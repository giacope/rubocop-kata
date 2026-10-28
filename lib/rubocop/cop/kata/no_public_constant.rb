# frozen_string_literal: true

class RuboCop::Cop::Kata::NoPublicConstant < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster
  include RuboCop::Cop::Kata::Ownership

  MSG = "`%s` is another object's public constant, shared state; ask `%s` what it means, and make it private."
  VALUE = /\A[A-Z][A-Z0-9]*(?:_[A-Z0-9]+)*\z/

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
    home = node.each_ancestor(:class, :module).first
    return false if found.empty? || candidates(node).any? { owned?(it) || namespace?(it) }
    !(home && found.include?(RuboCop::Kata::Nesting.new(home).qualified))
  end
end
