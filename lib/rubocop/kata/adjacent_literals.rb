# frozen_string_literal: true

# Layout/RedundantLineBreak, kept from joining adjacent string literals across
# their line break: it writes `'a' \` + `"b"` as `"a" + "b"`, a call that builds
# a new, unfrozen String where the literal was one frozen String.
module RuboCop::Kata::AdjacentLiterals
  def suitable_as_single_line?(node) = super && node.each_node(:dstr).none? { broken?(it) }

  private

  def broken?(node) = node.children.each_cons(2).any? { |left, right| left.last_line < right.first_line }
end

RuboCop::Cop::Layout::RedundantLineBreak.prepend(RuboCop::Kata::AdjacentLiterals)
