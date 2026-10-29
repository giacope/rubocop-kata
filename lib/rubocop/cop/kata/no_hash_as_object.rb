# frozen_string_literal: true

class RuboCop::Cop::Kata::NoHashAsObject < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster
  include RuboCop::Cop::Kata::Passage

  MSG = "%d keys travelling together are an object without a name."
  CALLS = %i[send csend super yield].freeze

  def on_hash(node)
    return if kwargs?(node) || table?(node) || protocol?(node)
    message = judged(node, node.pairs.size)
    add_offense(node, message:) if message
  end

  private

  def kwargs?(node)
    holder = node.parent
    CALLS.include?(holder&.type) && !node.braces?
  end

  def judged(node, count) = count < limit ? travel(node, count) : format(MSG, count)

  def table?(node)
    holder = carried(node).parent
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
    cop_config["Sorbet"] == true && RuboCop::Kata::Annotation.new(holder).wrapped(holder).equal?(value)
  end

  def protocol?(node)
    method = node.each_ancestor(:def, :defs).first
    method && listed?("AllowedMethods", method.method_name.to_s)
  end

  def limit = Integer(cop_config.fetch("MaxKeys", 4))
end
