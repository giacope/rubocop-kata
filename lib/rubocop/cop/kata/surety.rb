# frozen_string_literal: true

module RuboCop::Cop::Kata::Surety
  extend RuboCop::AST::NodePattern::Macros
  include RuboCop::Cop::Kata::Instantiation

  RANKS = %i[min max].freeze
  SOLIDS = %i[int float rational complex str dstr sym dsym].freeze
  NUMBERS = %i[+ - * / % ** -@ abs ceil clamp count floor length round size to_f to_i to_r to_s].freeze
  PROBES = %i[is_a? kind_of? instance_of?].freeze
  STARTS = %i[bos bol].freeze

  def_node_matcher :defaulted, <<~PATTERN
    {(block (send (const {nil? cbase} :Hash) :new) ...) (send (const {nil? cbase} :Hash) :new _)}
  PATTERN

  def_node_matcher :builder?, "(const {nil? cbase} {:Array :Dir :Hash :Set})"

  def_node_matcher :nil_kind?, "(const {nil? cbase} {:NilClass :Object :Kernel :BasicObject})"

  private

  def index?(call)
    arguments = call.arguments
    holder = call.receiver
    !(slice?(arguments) || matched?(arguments) || builder?(holder) || defaulted?(holder))
  end

  def slice?(arguments) = arguments.any?(&:range_type?) || (arguments.size == 2 && arguments.first.int_type?)

  def matched?(arguments)
    pattern = arguments.first
    arguments.one? && pattern.regexp_type? && !pattern.interpolation? && optional?(pattern.parsed_tree.expressions)
  end

  def optional?(parts)
    start = parts.first
    rest = start && start.type == :anchor && STARTS.include?(start.token) ? parts.drop(1) : parts
    rest.all? { it.quantified? && it.quantifier.min.zero? }
  end

  def single?(call) = !(call.arguments? || split?(call.receiver) || bounded?(call))

  def bounded?(call)
    holder = call.receiver
    RANKS.include?(call.method_name) && holder&.array_type? && holder.values.any? { solid?(it) }
  end

  def solid?(element)
    return assigned?(element.short_name) if element.const_type?
    SOLIDS.include?(element.type) || numeric?(element)
  end

  def numeric?(element) = element.send_type? && !element.receiver.nil? && NUMBERS.include?(element.method_name)

  def assigned?(name)
    processed_source.ast.each_node(:casgn).any? { it.short_name == name && SOLIDS.include?(it.expression&.type) }
  end

  def split?(holder) = holder&.send_type? && holder.method?(:split)

  def defaulted?(holder)
    name = holder.children.last
    stored = processed_source.ast.each_node(:casgn, :ivasgn).select { name && it.children[-2] == name }
    [*stored.map { it.children.last }, *values(holder)].any? { defaulted(it) }
  end

  def guarded?(call)
    call.each_ancestor.take_while { !it.type?(:def, :defs) }.any? { it.if_type? && holds?(it, call) }
  end

  def holds?(branch, call)
    held = branch.children[1]
    [call, *call.each_ancestor].any? { it.equal?(held) } && probed?(branch.condition, call)
  end

  def probed?(condition, call)
    return condition.children.any? { probed?(it, call) } if condition.and_type?
    return false unless condition.send_type? && PROBES.include?(condition.method_name)
    condition.receiver == call && !nil_kind?(condition.first_argument)
  end
end
