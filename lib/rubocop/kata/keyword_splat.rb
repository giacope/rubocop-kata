# frozen_string_literal: true

module RuboCop::Kata::KeywordSplat
  private

  def arguments_with_last_arg_pairs(node)
    last = node.last_argument
    return super if enforce_hash_argument_with_separator? || !last.hash_type? || last.braces?
    node.arguments[0..-2] + last.children
  end
end

RuboCop::Cop::Layout::ArgumentAlignment.prepend(RuboCop::Kata::KeywordSplat)
