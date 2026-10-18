# frozen_string_literal: true

class RuboCop::Cop::Kata::NoHashAsObject < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster
  MSG = "%d keys travelling together are an object without a name."
  CALLS = %i[send csend super yield].freeze

  def on_hash(node)
    count = node.pairs.size
    return if count < limit || kwargs?(node) || table?(node) || protocol?(node)
    add_offense(node, message: format(MSG, count))
  end

  private

  def kwargs?(node)
    holder = node.parent
    CALLS.include?(holder&.type) && (!node.braces? || node.equal?(holder.last_argument))
  end

  def table?(node)
    value = freezing?(node.parent) ? node.parent : node
    holder = value.parent
    return table?(holder.parent) if holder&.pair_type? && holder.value.equal?(value)
    holder&.casgn_type?
  end

  def freezing?(node) = node&.send_type? && node.method?(:freeze)

  def protocol?(node)
    method = node.each_ancestor(:def, :defs).first
    method && listed?("AllowedMethods", method.method_name.to_s)
  end

  def limit = Integer(cop_config.fetch("MaxKeys", 4))
end
