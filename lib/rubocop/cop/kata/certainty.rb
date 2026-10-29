# frozen_string_literal: true

module RuboCop::Cop::Kata::Certainty
  include RuboCop::Cop::Kata::Instantiation

  SURE = %i[str dstr sym dsym int float rational complex array hash regexp true false irange erange].freeze
  CERTAIN = %i[
    + - * / % ** -@ == != < > <= >= ! abs ceil clamp count filter_map flat_map floor format join keys length map
    merge new reject round select size sort sort_by split strip sum to_a to_f to_h to_i to_r to_s to_sym values
  ].freeze

  private

  def kept?(call)
    reached = reached(call)
    reached.any? && reached.all? { |definition| returns(definition).all? { certain?(it) } }
  end

  def certain?(node)
    return spoken?(node.children) if node.return_type?
    return certain?(node.children.fetch(-1)) if node.type?(:begin, :kwbegin, :or_asgn)
    return arms(node).all? { it && certain?(it) } if node.type?(:if, :case)
    SURE.include?(node.type) || answering?(node)
  end

  def spoken?(values) = values.size > 1 || (values.one? && certain?(values.first))

  def arms(node)
    node.if_type? ? [node.if_branch, node.else_branch] : [*node.when_branches.map(&:body), node.else_branch]
  end

  def answering?(node)
    call = node.any_block_type? ? node.send_node : node
    call.send_type? && (CERTAIN.include?(call.method_name) || call.predicate_method?)
  end

  def reached(call)
    holder = call.receiver
    found = holder.nil? || holder.self_type? ? local(call) : instances(holder, call.method_name)
    found.select(&:body)
  end

  def local(call)
    method = call.each_ancestor(:def, :defs, :sclass).first
    scope = call.each_ancestor(:class, :module, :sclass).first
    return [] unless method&.def_type? && scope && !scope.sclass_type?
    scope.each_descendant(:def).select { it.method?(call.method_name) && home?(it, scope) }
  end

  def home?(definition, scope) = definition.each_ancestor(:class, :module, :sclass).first.equal?(scope)

  def instances(holder, name) = classes(holder).flat_map { defined(it, name) }

  def defined(home, name)
    found = [*processed_source.ast.each_node(:def), *sources.defining(name.to_s, processed_source.file_path.to_s)]
    found.select { it.def_type? && it.method?(name) && housed?(it, home) }
  end

  def housed?(definition, home) = RuboCop::Kata::Nesting.new(definition).home == home
end
