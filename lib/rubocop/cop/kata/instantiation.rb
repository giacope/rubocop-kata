# frozen_string_literal: true

module RuboCop::Cop::Kata::Instantiation
  extend RuboCop::AST::NodePattern::Macros
  include RuboCop::Cop::Kata::Ownership

  SHADOWS = %i[arg optarg restarg kwarg kwoptarg kwrestarg blockarg shadowarg].freeze

  def_node_matcher :minted, "{(send $const :new ...) (any_block (send $const :new ...) ...)}"

  private

  def classes(holder)
    kinds = values(holder).map { minted(it) }
    return [] unless kinds.all? && kinds.uniq(&:source).one?
    owners(kinds.first).first(1)
  end

  def values(holder)
    case holder.type
    when :lvar then locals(holder)
    when :ivar then fields(holder)
    when :send then holder.receiver || holder.arguments? ? [holder] : answers(holder)
    else [holder]
    end
  end

  def locals(holder)
    name = holder.children.first
    method = holder.each_ancestor(:def, :defs).first
    return [] if method.nil? || method.each_node(*SHADOWS).any? { it.name == name }
    method.each_node(:lvasgn).select { it.children.first == name }.map { given(it) }
  end

  def fields(holder)
    processed_source.ast.each_node(:ivasgn).select { it.children.first == holder.children.first }.map { given(it) }
  end

  def answers(holder)
    name = holder.method_name
    found = processed_source.ast.each_node(:def).select { it.method?(name) && !it.arguments? && it.body }
    found.map { remembered(it.body) }
  end

  def given(store)
    holder = store.parent
    return holder.children.fetch(-1) if holder&.or_asgn_type? && holder.children.first.equal?(store)
    store.children.fetch(1) { store }
  end

  def remembered(body)
    value = body.begin_type? ? body.children.fetch(-1) : body
    value.or_asgn_type? ? value.children.fetch(-1) : value
  end
end
