# frozen_string_literal: true

module RuboCop::Cop::Kata::Memoization
  extend RuboCop::AST::NodePattern::Macros

  LOGIC = %i[and or].freeze

  def_node_matcher :vacancy?, "{(ivar %1) (send (ivar %1) {:nil? :! :present? :blank?})}"
  def_node_matcher :probe?, "{(:defined? (ivar %1)) (send {nil? self} :instance_variable_defined? (sym %1))}"

  private

  def memoized?(node)
    name = node.children.first
    return true if node.parent&.or_asgn_type? || fallback?(node.children[1], name)
    method = node.each_ancestor(:def, :defs).first
    !method.nil? && method.each_descendant(:if, :defined?, :send).any? { guard?(it, name) }
  end

  def fallback?(value, name) = value&.or_type? && vacancy?(value.lhs, name)

  def guard?(node, name)
    return probe?(node, name) unless node.if_type?
    test = node.condition
    [test, *(test.children if LOGIC.include?(test.type))].any? { vacancy?(it, name) }
  end
end
