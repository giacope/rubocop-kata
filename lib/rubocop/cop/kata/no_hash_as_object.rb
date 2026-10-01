# frozen_string_literal: true

class RuboCop::Cop::Kata::NoHashAsObject < RuboCop::Cop::Base
  MSG = "%d keys travelling together are an object without a name."
  CALLS = %i[send csend super yield].freeze

  def on_hash(node)
    count = node.pairs.size
    return if count < limit || kwargs?(node) || table?(node)
    add_offense(node, message: format(MSG, count))
  end

  private

  def kwargs?(node)
    holder = node.parent
    CALLS.include?(holder&.type) && (!node.braces? || node.equal?(holder.last_argument))
  end

  def table?(node)
    holder = node.parent
    holder = holder.parent if holder&.send_type? && holder.method?(:freeze)
    holder&.casgn_type?
  end

  def limit = Integer(cop_config.fetch("MaxKeys", 4))
end
