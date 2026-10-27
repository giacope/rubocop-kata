# frozen_string_literal: true

module RuboCop::Kata::AttributeCopy
  def on_send(node)
    super if plain?(node)
  end

  def on_csend(node)
    super if plain?(node)
  end

  private

  def plain?(node)
    return true if node.method?(:[]=) || !node.assignment_method?
    names = [node.method_name, node.method_name.to_s.delete_suffix("=").to_sym]
    node.receiver&.self_type? && processed_source.ast.each_node(:def).none? { names.include?(it.method_name) }
  end
end

RuboCop::Cop::Lint::SelfAssignment.prepend(RuboCop::Kata::AttributeCopy)
