# frozen_string_literal: true

class RuboCop::Cop::Kata::NoHashAsObject < RuboCop::Cop::Base
  MSG = "%d keys travelling together are an object without a name."
  CALLS = %i[send csend super yield].freeze

  def on_hash(node)
    return if node.pairs.size < limit
    return if kwargs?(node) || table?(node)
    add_offense(node, message: format(MSG, node.pairs.size))
  end

  private

  def kwargs?(node)
    CALLS.include?(node.parent&.type) && (!node.braces? || node.equal?(node.parent.last_argument))
  end

  def table?(node)
    holder = node.parent
    holder = holder.parent if holder&.send_type? && holder.method?(:freeze)
    holder&.casgn_type?
  end

  def limit = Integer(cop_config.fetch("MaxKeys", 4))
end
