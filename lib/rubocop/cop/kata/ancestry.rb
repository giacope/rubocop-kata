# frozen_string_literal: true

module RuboCop::Cop::Kata::Ancestry
  include RuboCop::Cop::Kata::Pedigree

  private

  def override?(node)
    scope = node.each_ancestor(:class, :module).first
    return false unless scope
    name = node.method_name.to_s
    project.ancestors(RuboCop::Kata::Nesting.new(scope).qualified).drop(1).any? { project.defines?(it, name) }
  end

  def hook?(node)
    scope = node.each_ancestor(:class, :module).first
    return false unless node.defs_type? && scope&.class_type?
    line = project.superclasses(RuboCop::Kata::Nesting.new(scope).qualified)
    leaves?(line) && (reached?(node, line) || dispatched?(node))
  end

  def leaves?(line) = !line.empty? && !project.records.key?(line.last)

  def reached?(node, line)
    node.each_descendant(:super, :zsuper).any? && line.none? { project.defines?(it, "self.#{node.method_name}") }
  end

  def dispatched?(node) = project.owners("self.#{node.method_name}").size > 1 && !inventory.sent?(node.method_name)
end
