# frozen_string_literal: true

class RuboCop::Cop::Kata::ConstructorDiscipline < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster

  MSG = "A constructor assigns; it does not compute. Move `%s` out of `initialize`."
  CONVERSION = /\Ato_[a-z]+\z/

  def on_def(node)
    return unless node.method?(:initialize)
    node.each_descendant(:send, :csend) do |send|
      name = send.method_name.to_s
      next if listed?("AllowedMethods", name) || CONVERSION.match?(name) || state?(send)
      next if send.each_ancestor.take_while { !it.equal?(node) }.any? { excused?(it) }
      add_offense(send, message: format(MSG, name))
    end
  end

  private

  def excused?(node)
    return node.lambda_or_proc? || state?(node.send_node) if node.any_block_type?
    raised?(node) || (node.if_type? && node.branches.all? { raised?(it) })
  end

  def state?(send)
    receiver = send.receiver
    send.method?(:new) && receiver&.const_type? && listed?("AllowedConstructors", receiver.const_name)
  end

  def raised?(node) = node&.send_type? && node.method?(:raise)
end
