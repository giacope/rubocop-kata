# frozen_string_literal: true

class RuboCop::Cop::Kata::NoNilReturn < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster
  include RuboCop::Cop::Kata::Answer

  MSG = "`%s` returns nil; return a null object, or fail fast."
  SOURCE = "`%s` passes on the nil `%s` can return; return a null object, or fail fast."
  OPEN = "`%s` returns nil when this `%s` does not hold; answer that case with a null object, or fail fast."
  BLOCK = "This block returns nil; return a null object, or fail fast."
  SEARCHES = %i[detect find].freeze
  SINGLES = %i[first last min max sample].freeze
  LOOKUPS = %i[[] dig find_by match index find_index rindex presence try].freeze
  COMMANDS = %i[call close delete destroy perform run save touch update].freeze
  SCOPES = %i[def defs].freeze
  INNER = { begin: -1, kwbegin: -1, or_asgn: 1, rescue: 0, ensure: 0 }.freeze

  def_node_matcher :defaulted, <<~PATTERN
    {(block (send (const {nil? cbase} :Hash) :new) ...) (send (const {nil? cbase} :Hash) :new _)}
  PATTERN

  def on_def(node)
    return unless node.body && judged?(node)
    returns(node).each { visit(it, node) }
  end

  alias on_defs on_def

  def on_block(node)
    tail = last(node.body)
    add_offense(tail, message: BLOCK) if tail&.nil_type?
  end

  alias on_numblock on_block
  alias on_itblock on_block

  private

  def judged?(method)
    name = method.method_name.to_s
    !(method.predicate_method? || method.assignment_method? || listed?("AllowedMethods", name))
  end

  def returns(method)
    exits = method.each_descendant(:return).select { it.each_ancestor(*SCOPES).first.equal?(method) }
    [method.body, *exits]
  end

  def visit(node, method)
    return explicit(node, method) if node.return_type?
    ends(node).each { |tail, branch| judge(tail, branch, method) }
  end

  def explicit(node, method)
    values = node.children
    return unless values.one?
    value = values.first
    return add_offense(node, message: format(MSG, method.method_name)) if value.nil_type?
    visit(value, method)
  end

  def judge(tail, branch, method)
    name = method.method_name
    return add_offense(tail, message: format(MSG, name)) if tail.nil_type?
    return add_offense(branch.loc.keyword, message: format(OPEN, name, branch.keyword)) if branch
    sources(tail).each { add_offense(it, message: format(SOURCE, name, label(it))) unless it.method?(name) }
  end

  def ends(node)
    return [] unless node
    return ends(node.children[INNER.fetch(node.type)]) if INNER.key?(node.type)
    return branches(node) if node.type?(:if, :case)
    [[node, nil]]
  end

  def branches(node)
    arms = node.if_type? ? [node.if_branch, node.else_branch] : [*node.when_branches.map(&:body), node.else_branch]
    found = arms.compact.flat_map { ends(it) }
    return found unless open?(node, arms, found)
    [*found, [node, node]]
  end

  def open?(node, arms, found)
    missing = node.if_type? ? arms.include?(nil) : arms.last.nil?
    missing && found.any? && found.all? { |tail, branch| branch.nil? && valued?(tail) }
  end

  def valued?(node) = value?(node) || sources(node).any?

  def last(node) = node&.type?(:begin, :kwbegin) ? node.children.last : node

  def sources(node)
    return [node].reject { command?(it.method_name) } if node.csend_type?
    block = node.any_block_type?
    call = block ? node.send_node : node
    call.send_type? && lookup?(call, block || call.block_argument?) ? [call] : []
  end

  def lookup?(call, block)
    name = call.method_name
    return index?(call) if name == :[]
    return block if SEARCHES.include?(name)
    return single?(call) if SINGLES.include?(name)
    LOOKUPS.include?(name) && (!call.receiver.nil? || name == :find_by)
  end

  def index?(call) = !(slice?(call.arguments) || defaulted?(call.receiver))

  def slice?(arguments) = arguments.any?(&:range_type?) || (arguments.size == 2 && arguments.first.int_type?)

  def single?(call) = !(call.arguments? || split?(call.receiver))

  def split?(holder) = holder&.send_type? && holder.method?(:split)

  def defaulted?(holder)
    return false unless holder&.type?(:const, :ivar)
    name = holder.children.last
    processed_source.ast.each_node(:casgn, :ivasgn).any? { it.children[-2] == name && defaulted(it.children.last) }
  end

  def command?(name) = name.end_with?("!") || COMMANDS.include?(name)

  def label(call) = call.csend_type? ? "&.#{call.method_name}" : call.method_name
end
