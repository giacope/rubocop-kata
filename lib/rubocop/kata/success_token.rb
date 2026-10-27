# frozen_string_literal: true

module RuboCop::Kata::SuccessToken
  COMMAND = "`%s` acts, then answers a boolean: a command returns nothing (or `self`) and raises when it " \
    "fails; a `?` would make it a query that changes state."
  BRANCHING = %i[if while until case].freeze
  COMPOUND = [*BRANCHING, :when, :begin, :kwbegin].freeze
  WRITES = %i[ivasgn cvasgn gvasgn op_asgn and_asgn].freeze
  RAISES = %i[raise fail].freeze

  def add_offense(subject, message: nil, **)
    return super unless message == self.class::MSG_PREDICATE
    method = processed_source.ast.each_node(:def, :defs).find { it.loc.name == subject }
    acts?(method.body) ? super(subject, **, message: format(COMMAND, method.method_name)) : super
  end

  private

  def acts?(body) = body.begin_type? && body.children[0...-1].any? { effect?(it) }

  def effect?(node)
    return false unless node.is_a?(RuboCop::AST::Node)
    return command?(node) if node.call_type?
    return write?(node) if WRITES.include?(node.type)
    compound?(node) && parts(node).any? { effect?(it) }
  end

  def command?(call) = !(call.receiver.nil? && RAISES.include?(call.method_name))

  def write?(node) = !(node.shorthand_asgn? && node.lhs.lvasgn_type?)

  def compound?(node) = COMPOUND.include?(node.type) || node.any_block_type?

  def parts(node)
    return node.children.drop(1) if BRANCHING.include?(node.type)
    node.when_type? || node.any_block_type? ? [node.body] : node.children
  end
end

RuboCop::Cop::Registry.global.find_by_cop_name("Naming/PredicateMethod")&.prepend(RuboCop::Kata::SuccessToken)
