# frozen_string_literal: true

class RuboCop::Cop::Kata::NoClassMethodLogic < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster

  MSG = "`%s` puts logic on the class; classes construct, instances work."
  BAG = "`%s` turns the module into a bag of functions; give the logic an object that holds its data."

  RESTRICT_ON_SEND = %i[module_function extend].freeze

  def_node_matcher :functions?, "{(send nil? :module_function ...) (send nil? :extend self)}"

  def on_defs(node) = check(node)

  def on_def(node)
    check(node) if node.each_ancestor(:sclass, :class, :module, :any_block).first&.sclass_type?
  end

  def on_send(node)
    return unless functions?(node) && node.each_ancestor(:class, :module, :any_block).first&.module_type?
    add_offense(node, message: format(BAG, node.method?(:extend) ? "extend self" : "module_function"))
  end

  private

  def check(node)
    name = node.method_name.to_s
    return if constructor?(name)
    add_offense(node.loc.name, message: format(MSG, name))
  end

  def constructor?(name) = name.start_with?("from_") || allowed?(name)
end
