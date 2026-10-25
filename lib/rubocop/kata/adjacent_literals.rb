# frozen_string_literal: true

module RuboCop::Kata::AdjacentLiterals
  def add_offense(node, **)
    return super unless node.each_node(:dstr).any? { broken?(it) }
    super(node, **, &nil)
  end

  private

  def broken?(node) = node.children.each_cons(2).any? { |left, right| left.last_line < right.first_line }
end

RuboCop::Cop::Layout::RedundantLineBreak.prepend(RuboCop::Kata::AdjacentLiterals)
