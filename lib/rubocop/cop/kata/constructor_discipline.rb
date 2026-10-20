# frozen_string_literal: true

class RuboCop::Cop::Kata::ConstructorDiscipline < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster

  MSG = "A constructor assigns; it does not compute. Move `%s` out of `initialize`."
  CONVERSION = /\Ato_[a-z]+\z/
  FRESH = %i[+@ -@ compare_by_identity].freeze
  LITERALS = %i[str dstr hash array].freeze

  def on_def(node)
    return unless node.method?(:initialize)
    node.each_descendant(:send, :csend) { judge(it, node) }
  end

  private

  def judge(send, root)
    name = send.method_name
    return if allowed?(send) || exempt?(send, root)
    add_offense(send, message: format(MSG, name))
  end

  def allowed?(send)
    name = send.method_name.to_s
    listed?("AllowedMethods", name) || CONVERSION.match?(name) || state?(send)
  end

  def state?(send)
    receiver = send.receiver
    return own?(receiver) if FRESH.include?(send.method_name)
    send.method?(:new) && receiver&.const_type? && listed?("AllowedConstructors", receiver.const_name)
  end

  def own?(receiver)
    receiver = receiver.send_node if receiver&.any_block_type?
    return false if receiver.nil?
    LITERALS.include?(receiver.type) || (receiver.send_type? && state?(receiver))
  end

  def exempt?(send, root)
    send.each_ancestor.take_while { !it.equal?(root) }.any? { deferred?(it) || raised?(it) || guard?(it) }
  end

  def deferred?(node) = node.any_block_type? && (node.lambda_or_proc? || state?(node.send_node))

  def raised?(node) = node&.send_type? && listed?("RaisingMethods", node.method_name.to_s)

  def guard?(node) = node.if_type? && node.branches.all? { raised?(it) }
end
