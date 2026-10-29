# frozen_string_literal: true

class RuboCop::Cop::Kata::NoNilReturn < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster
  include RuboCop::Cop::Kata::Answer
  include RuboCop::Cop::Kata::Surety
  include RuboCop::Cop::Kata::Certainty

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

  def on_def(node)
    return unless node.body && judged?(node)
    name = node.method_name
    found = returns(node).flat_map { visit(it, name) }
    found.reject { |_, _, call| passed?(call, name) }.each { |place, message| add_offense(place, message:) }
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

  def visit(node, name)
    return explicit(node, name) if node.return_type?
    ends(node).flat_map { |tail, branch| judge(tail, branch, name) }
  end

  def explicit(node, name)
    values = node.children
    return [] unless values.one?
    value = values.first
    return [[node, format(MSG, name), node]] if value.nil_type?
    visit(value, name)
  end

  def judge(tail, branch, name)
    return [[tail, format(MSG, name), tail]] if tail.nil_type?
    return [[branch.loc.keyword, format(OPEN, name, branch.keyword), branch]] if branch
    lookups(tail).reject { guarded?(it) }.map { [it, format(SOURCE, name, label(it)), it] }
  end

  def ends(node)
    return [] unless node
    return ends(node.children[INNER.fetch(node.type)]) if INNER.key?(node.type)
    return branches(node) if node.type?(:if, :case)
    [[node, nil]]
  end

  def branches(node)
    paths = arms(node)
    found = paths.compact.flat_map { ends(it) }
    return found unless open?(paths, found)
    [*found, [node, node]]
  end

  def open?(arms, found) = arms.include?(nil) && found.any? && found.all? { |value, arm| arm.nil? && valued?(value) }

  def valued?(node) = value?(node) || lookups(node).any?

  def last(node) = node&.type?(:begin, :kwbegin) ? node.children.last : node

  def lookups(node)
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

  def passed?(call, name) = call.call_type? && (call.method?(name) || kept?(call))

  def command?(name) = name.end_with?("!") || COMMANDS.include?(name)

  def label(call) = call.csend_type? ? "&.#{call.method_name}" : call.method_name
end
