# frozen_string_literal: true

class RuboCop::Cop::Kata::ConstructorDiscipline < RuboCop::Cop::Base
  MSG = "A constructor assigns; it does not compute. Move `%s` out of `initialize`."

  ALLOWED = %i[raise freeze].freeze

  def on_def(node)
    return unless node.method?(:initialize)
    node.each_descendant(:send, :csend) do |send|
      next if ALLOWED.include?(send.method_name) || exempt?(send, node)
      add_offense(send, message: format(MSG, send.method_name))
    end
  end

  private

  def exempt?(send, root)
    send.each_ancestor.take_while { !it.equal?(root) }.any? { deferred?(it) || raised?(it) || guard?(it) }
  end

  def deferred?(node) = node.any_block_type? && node.lambda_or_proc?

  def raised?(node) = node&.send_type? && node.method?(:raise)

  def guard?(node) = node.if_type? && node.branches.all? { raised?(it) }
end
