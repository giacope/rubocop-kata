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
    value = enclosing(node)
    holder = value.parent
    return table?(holder.parent) if holder&.pair_type? && holder.value.equal?(value)
    return table?(holder) if holder&.array_type?
    holder&.casgn_type? || mapping?(holder)
  end

  def mapping?(holder) = holder&.send_type? && listed?("TableMethods", holder.method_name.to_s)

  def enclosing(node)
    value = node
    value = value.parent while freezing?(value.parent) || annotated?(value)
    value
  end

  def freezing?(node) = node&.send_type? && node.method?(:freeze)

  def annotated?(value)
    holder = value.parent
    cop_config["Sorbet"] == true && holder&.send_type? && RuboCop::Kata::Annotation.new(holder).wrapper? &&
      holder.first_argument.equal?(value)
  end

  def protocol?(node)
    method = node.each_ancestor(:def, :defs).first
    method && listed?("AllowedMethods", method.method_name.to_s)
  end

  def limit = Integer(cop_config.fetch("MaxKeys", 4))
end
