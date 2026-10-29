# frozen_string_literal: true

module RuboCop::Cop::Kata::Ancestry
  include RuboCop::Cop::Kata::Pedigree

  private

  def override?(node)
    scope = node.each_ancestor(:class, :module).first
    return false unless scope
    name = node.method_name.to_s
    project.ancestors(RuboCop::Kata::Nesting.new(scope).qualified).drop(1).any? { project[it].defines?(name) }
  end

  def hook?(node) = defaulted?(node) || framed?(node)

  def defaulted?(node)
    scope = node.each_ancestor(:class, :module).first
    return false unless scope && static?(node)
    name = RuboCop::Kata::Nesting.new(scope).qualified
    method = node.method_name.to_s
    return scope.class_type? && inheritance.extended?(name, method) if node.each_ancestor(:def).none?
    scope.module_type? && inheritance.instance?(name, method)
  end

  def static?(node) = node.defs_type? || node.each_ancestor(:class, :module, :sclass).first.sclass_type?

  def framed?(node)
    line = frame(node)
    node.defs_type? && leaves?(line) && (reached?(node, line) || dispatched?(node))
  end

  def frame(node)
    scope = node.each_ancestor(:class, :module).first
    scope&.class_type? ? project.superclasses(RuboCop::Kata::Nesting.new(scope).qualified) : []
  end

  def leaves?(line) = !line.empty? && !project.to_h.key?(line.last)

  def exposed?(node, holder) = node.def_type? && holder&.class_type? && node_visibility(node) == :public

  def reached?(node, line)
    node.each_descendant(:super, :zsuper).any? && line.none? { project[it].defines?("self.#{node.method_name}") }
  end

  def dispatched?(node) = inheritance.owners("self.#{node.method_name}").size > 1 && !repertoire.sent?(node.method_name)
end
