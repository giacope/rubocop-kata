# frozen_string_literal: true

class RuboCop::Cop::Kata::NoPublicConstant < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster
  include RuboCop::Cop::Kata::Ownership

  MSG = "`%s` is another object's public constant, shared state; ask `%s` what it means, and make it private."
  VALUE = /\A[A-Z][A-Z0-9]*(?:_[A-Z0-9]+)*\z/

  def_node_matcher :factory?, "(any_block (send (const {nil? cbase} {:Class :Struct :Data}) {:new :define} ...) ...)"

  def on_const(node)
    holder = node.namespace
    return unless holder&.const_type? && value?(node)
    add_offense(node, message: format(MSG, node.source, holder.source)) if foreign_owner?(holder, node)
  end

  private

  def value?(node)
    name = node.short_name.to_s
    VALUE.match?(name) && name.size > 1 && !allowed?(name) && !scoping?(node)
  end

  def scoping?(node) = node.parent&.const_type? && node.parent.namespace.equal?(node)

  def foreign_owner?(holder, node)
    found = owners(holder)
    return false if found.empty? || candidates(node).any? { owned?(it) || namespace?(it) }
    !found.include?(home(node))
  end

  def home(node)
    scope = node.each_ancestor(:class, :module, :any_block).find { !it.any_block_type? || body?(it) }
    return "" if scope.nil?
    return RuboCop::Kata::Nesting.new(scope).qualified unless scope.any_block_type?
    assignment = scope.parent
    [*RuboCop::Kata::Nesting.new(assignment).names.first(1), assignment.const_name].join("::")
  end

  def body?(block) = factory?(block) && block.parent&.casgn_type? && block.parent.expression.equal?(block)
end
