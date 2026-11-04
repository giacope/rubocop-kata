# frozen_string_literal: true

class RuboCop::Kata::ThreadSlot
  extend RuboCop::AST::NodePattern::Macros

  WRITES = %i[[]= store delete].freeze

  def_node_matcher :slot, <<~PATTERN
    (send ${(send (const {nil? cbase} :Thread) :current) (const {nil? cbase} :Fiber)} {:[] :[]=} $_ ...)
  PATTERN

  def_node_matcher :saved, "(lvasgn $_ (send %1 :[] %2))"

  def_node_matcher :set?, "(send %1 :[]= %2 _)"

  def_node_matcher :restored, "(send %1 :[]= %2 (lvar $_))"

  def initialize(access, root)
    @access = access
    @root = root
  end

  def scoped?
    slot(@access) do |holder, key|
      writes = @root.each_node(:send).select { it.receiver == holder && it.first_argument == key && write?(it) }
      return writes.any? && writes.all? { scope?(it.each_ancestor(:ensure).first, holder, key) }
    end
    false
  end

  private

  def write?(call) = WRITES.include?(call.method_name)

  def scope?(clause, holder, key)
    return false if clause.nil?
    body, branch = clause.children.map { it ? it.each_node.to_a : [] }
    names = body.filter_map { saved(it, holder, key) }
    body.any?(&:yield_type?) && body.any? { set?(it, holder, key) } &&
      branch.any? { names.include?(restored(it, holder, key)) }
  end
end
