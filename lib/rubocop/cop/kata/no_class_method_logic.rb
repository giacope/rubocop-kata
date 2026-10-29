# frozen_string_literal: true

class RuboCop::Cop::Kata::NoClassMethodLogic < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster
  include RuboCop::Cop::Kata::Ancestry

  MSG = "`%s` puts logic on the class; classes construct, instances work."
  LITERAL = "`%s` only returns a literal; make it a constant."
  LITERALS = %i[str dstr sym dsym int float array hash true false nil regexp irange erange].freeze
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
    return if constructor?(name) || builds?(node) || hook?(node)
    add_offense(node.loc.name, message: format(constant?(node) ? LITERAL : MSG, name))
  end

  def constant?(node) = literal?(node.body) && node.arguments.empty? && !shared?(node)

  def literal?(body) = LITERALS.include?(body&.type) && body.each_node(:send, :lvar, :ivar).none?

  def shared?(node) = inheritance.owners("self.#{node.method_name}").size > 1

  def constructor?(name) = name.start_with?("from_") || allowed?(name)

  def builds?(node)
    tail = node.body
    tail = tail.children.last if tail&.begin_type?
    tail&.send_type? && tail.method?(:new) && own?(tail.receiver, node)
  end

  def own?(receiver, node)
    return true if receiver.nil? || receiver.self_type?
    holder = node.each_ancestor(:class).first
    receiver.const_type? && !holder.nil? && receiver.short_name == holder.identifier.short_name
  end
end
