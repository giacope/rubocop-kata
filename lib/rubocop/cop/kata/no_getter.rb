# frozen_string_literal: true

class RuboCop::Cop::Kata::NoGetter < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Exposure

  MACRO = "`attr_reader` exposes %s as a getter; tell the object what to do with its fields, or have it print itself."
  READER = "`%s` is a getter; tell the object what to do with `%s`, or have it print itself."
  BAG = "`%s` mints a getter for every field, a data bag; write a class whose methods do the work with its fields."

  RESTRICT_ON_SEND = %i[attr_reader attr new define].freeze

  def_node_matcher :bag, "(send (const {nil? cbase} ${:Struct :Data}) {:new :define} ...)"

  def on_send(node)
    return judge_bag(node) unless node.method?(:attr_reader) || node.method?(:attr)
    return if node.receiver || hidden?(node) || node.arguments.empty?
    add_offense(node.loc.selector, message: format(MACRO, fields(node)))
  end

  def on_def(node)
    field = node.body
    return unless field&.ivar_type? && field.children.first == :"@#{node.method_name}" && !hidden?(node)
    add_offense(node.loc.name, message: format(READER, node.method_name, field.source))
  end

  private

  def judge_bag(node)
    bag(node) do |kind|
      label = "#{kind}.#{node.method_name}"
      add_offense(node, message: format(BAG, label)) if node.arguments.any? { it.type?(:sym, :str) }
    end
  end

  def fields(node) = node.arguments.map { "`#{it.source.delete_prefix(":")}`" }.join(", ")
end
