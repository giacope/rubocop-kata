# frozen_string_literal: true

class RuboCop::Cop::Kata::NoHashAsObject < RuboCop::Cop::Base
  MSG = "%d keys travelling together are an object without a name."

  def on_hash(node)
    return if node.pairs.size < limit
    return if kwargs?(node)
    add_offense(node, message: format(MSG, node.pairs.size))
  end

  private

  def kwargs?(node) = node.parent&.send_type? && node.equal?(node.parent.last_argument)

  def limit = Integer(cop_config.fetch("MaxKeys", 4))
end
