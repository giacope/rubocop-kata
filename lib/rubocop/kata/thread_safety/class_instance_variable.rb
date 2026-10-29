# frozen_string_literal: true

require "rubocop-thread_safety"

class RuboCop::Kata::ThreadSafety::ClassInstanceVariable < RuboCop::Cop::ThreadSafety::ClassInstanceVariable
  def_node_matcher :mixin?, "(block (send (const {nil? cbase} :Module) :new) ...)"

  def_node_matcher :mixing?, "(send const {:include :prepend} ...)"

  private

  def class_method_definition?(node) = super && !mixed?(node)

  def mixed?(node)
    method = node.each_ancestor(:def, :defs).first
    return false unless method&.def_type?
    scope = method.each_ancestor(:block, :class, :module, :sclass).first
    mixin?(scope) && mixing?(scope.parent)
  end
end
