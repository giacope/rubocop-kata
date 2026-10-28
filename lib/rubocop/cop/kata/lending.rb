# frozen_string_literal: true

module RuboCop::Cop::Kata::Lending
  include RuboCop::Kata::Order

  LENT = %i[arg optarg kwarg kwoptarg].freeze
  SCOPES = %i[def defs sclass].freeze
  SHADOWS = %i[arg optarg restarg kwarg kwoptarg kwrestarg blockarg shadowarg].freeze

  private

  def lent(method) = method.arguments.select { LENT.include?(it.type) }.map(&:name)

  def borrowed?(target, method, names = lent(method))
    return false unless target&.lvar_type? && names.include?(target.children.first)
    !outside?(target, method) && !fresh?(target, method)
  end

  def outside?(target, method)
    target.each_ancestor.take_while { !it.equal?(method) }.any? { scope?(it, target.children.first) }
  end

  def scope?(node, name)
    SCOPES.include?(node.type) || (node.block_type? && node.children[1].each_node(*SHADOWS).any? { it.name == name })
  end

  def fresh?(target, method)
    name = target.children.first
    method.each_descendant(:lvasgn).any? { it.children.first == name && precedes?(it, target) }
  end
end
