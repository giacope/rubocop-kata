# frozen_string_literal: true

class RuboCop::Kata::ThreadSlot
  extend RuboCop::AST::NodePattern::Macros

  WRITES = %i[[]= store delete].freeze
  ACCESS = %i[[] []=].freeze

  def_node_matcher :current?, "(send (const {nil? cbase} :Thread) :current)"

  def_node_matcher :fiber?, "(const {nil? cbase} :Fiber)"

  def_node_matcher :saved, "(lvasgn $_ $(send _ :[] _))"

  def_node_matcher :restored, "(send _ :[]= _ (lvar $_))"

  def initialize(access, root)
    @access = access
    @root = root
  end

  def scoped?
    return false unless ACCESS.include?(@access.method_name)
    kind = holder(@access.receiver)
    return false if kind == :none
    writes = @root.each_node(:send).select { write?(it) && same?(it, kind) }
    writes.any? && writes.all? { scope?(it.each_ancestor(:ensure).first, kind) }
  end

  private

  def write?(call) = WRITES.include?(call.method_name)

  def same?(call, kind) = holder(call.receiver) == kind && call.first_argument == @access.first_argument

  def holder(node)
    return :fiber if fiber?(node)
    current?(node) || (node&.lvar_type? && bound?(node)) ? :thread : :none
  end

  def bound?(local)
    scope = local.each_ancestor(:def, :defs).first || @root
    values = scope.each_node(:lvasgn).select { it.children.first == local.children.first }.map(&:expression)
    values.any? && values.all? { current?(it) }
  end

  def scope?(clause, kind)
    return false if clause.nil?
    body, branch = clause.children.map { it ? it.each_node.to_a : [] }
    names = body.filter_map { local(it, kind) }
    body.any?(&:yield_type?) && body.any? { set?(it, kind) } && branch.any? { names.include?(back(it, kind)) }
  end

  def set?(node, kind) = node.send_type? && node.method?(:[]=) && same?(node, kind)

  def back(node, kind) = set?(node, kind) && restored(node)

  def local(node, kind)
    saved(node) { |name, read| name if same?(read, kind) }
  end
end
