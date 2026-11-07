# frozen_string_literal: true

class RuboCop::Kata::ForkHook
  extend RuboCop::AST::NodePattern::Macros

  HOOK = :_fork

  def_node_matcher :built?, "(casgn _ _ (block (send (const {nil? cbase} :Module) :new) ...))"

  def initialize(names, processed, sources)
    @names = names
    @processed = processed
    @sources = sources
  end

  def hook?
    bodies = trees.flat_map { |tree| tree.each_node(:module, :casgn).select { named?(it) } }.filter_map { body(it) }
    bodies.any? && bodies.all? { it.def_type? && it.method?(HOOK) }
  end

  private

  def trees
    elsewhere = @sources.defining(HOOK.to_s, @processed.file_path.to_s)
    [@processed.ast, *elsewhere.filter_map { it.each_ancestor.to_a.last }]
  end

  def named?(node) = (node.module_type? || built?(node)) && @names.include?(qualified(node))

  def qualified(node)
    nesting = RuboCop::Kata::Nesting.new(node)
    node.module_type? ? nesting.qualified : [*nesting.names.first(1), node.const_name].join("::")
  end

  def body(node) = node.module_type? ? node.body : node.expression.body
end
