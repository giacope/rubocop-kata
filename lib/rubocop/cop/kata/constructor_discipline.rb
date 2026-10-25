# frozen_string_literal: true

class RuboCop::Cop::Kata::ConstructorDiscipline < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster
  include RuboCop::Cop::Kata::Tally

  MSG = "A constructor assigns; it does not compute. Move %s out of `initialize`."
  CONVERSION = /\Ato_[a-z]+\z/
  FRESH = %i[+@ -@ compare_by_identity].freeze
  LITERALS = %i[str dstr hash array].freeze

  def on_def(node)
    return unless node.method?(:initialize)
    calls = node.body&.each_node(:send, :csend).to_a
    moved = calls.reject { allowed?(it) || exempt?(it, node) || typing?(it) }
    add_offense(moved.first, message: format(MSG, tally(moved.map(&:method_name)))) unless moved.empty?
  end

  private

  def allowed?(send)
    name = send.method_name.to_s
    listed?("AllowedMethods", name) || CONVERSION.match?(name) || state?(send) || written?(send)
  end

  def written?(send) = send.receiver&.self_type? && send.setter_method? && !send.method?(:[]=)

  def state?(send)
    receiver = send.receiver
    return own?(receiver) if FRESH.include?(send.method_name)
    send.method?(:new) && receiver&.const_type? && listed?("AllowedConstructors", receiver.const_name)
  end

  def own?(receiver)
    receiver = receiver.send_node if receiver&.any_block_type?
    return true if receiver.nil?
    LITERALS.include?(receiver.type) || (receiver.send_type? && state?(receiver))
  end

  def exempt?(send, root)
    send.each_ancestor.take_while { !it.equal?(root) }.any? { deferred?(it) || raised?(it) || guard?(it) }
  end

  def typing?(send) = cop_config["Sorbet"] == true && RuboCop::Kata::Annotation.new(send).typing?

  def deferred?(node) = node.any_block_type? && (node.lambda_or_proc? || state?(node.send_node))

  def raised?(node) = node&.send_type? && listed?("RaisingMethods", node.method_name.to_s)

  def guard?(node) = node.if_type? && node.branches.all? { raised?(it) }
end
