# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT
# Derived from rubocop-elegant (https://github.com/yegor256/rubocop-elegant), see LICENSE.txt

RSpec.describe(RuboCop::Cop::Kata::PairedBrackets) do
  let(:cop) { described_class.new(RuboCop::Config.new) }

  it_behaves_like(
    "tabled cop", allowed: {
      "paired_parens_on_same_line" => "foo(1, 2)",
      "paired_square_brackets_on_same_line" => "[1, 2, 3]",
      "paired_curly_braces_on_same_line" => "{ a: 1, b: 2 }",
      "opener_ends_line_closer_starts_line" => "foo(\n  1\n)",
      "split_square_brackets_at_line_edges" => "[\n  1,\n  2\n]",
      "split_curly_braces_at_line_edges" => "{\n  a: 1\n}",
      "block_brace_paired_on_same_line" => "[1].each { |x| x }",
      "trailing_comment_after_opener" => "foo( # explain\n  1\n)",
      "trailing_chain_after_closer" => "foo(\n  1\n).bar",
      "brackets_in_string_literal" => 'puts "(hello)"',
      "brackets_in_string_interpolation" => %(puts "value=\#{x}"),
      "brackets_in_percent_words_array" => "%w[a b c]",
      "brackets_in_percent_symbols_array" => "%i(a b c)",
      "brackets_in_comments" => "# (a)\nfoo",
      "indexer_brackets" => "arr[0]",
      "empty_parens_paired" => "foo()",
      "empty_parens_split_at_edges" => "foo(\n)",
      "nested_pairs_at_line_edges" => "foo(\n  bar(\n    1\n  )\n)"
    }, violations: {
      "opener_in_middle_of_line" => ["foo(bar(\n  1\n))", 2],
      "closer_not_at_start_of_line" => ["foo(\n  1)", 1],
      "opener_not_at_end_of_line" => ["foo(1,\n  2\n)", 1],
      "split_square_brackets_in_middle" => ["[1,\n 2]", 2],
      "block_brace_with_argument_split" => ["[1].each { |x|\n  x\n}", 1],
      "closer_in_middle_when_chained" => ["foo(\n  1).bar", 1],
      "lambda_brace_keeps_its_own_closer" => ["[-> { 1 }, baz(\n  2\n)]", 2]
    }, corrections: {
      "closer_not_at_start_of_line" => ["foo(\n  1)", "foo(\n  1\n)"],
      "opener_not_at_end_of_line" => ["foo(1,\n  2\n)", "foo(\n  1,\n  2\n)"],
      "split_square_brackets_in_middle" => ["[1,\n 2]", "[\n  1,\n 2\n]"],
      "closer_in_middle_when_chained" => ["foo(\n  1).bar", "foo(\n  1\n).bar"],
      "opener_in_middle_of_line" => ["foo(bar(\n  1\n))", "foo(\n  bar(\n  1\n)\n)"],
      "opener_with_indent" => ["  foo(1,\n    2\n  )", "  foo(\n    1,\n    2\n  )"],
      "closer_with_indent" => ["  foo(\n    1)", "  foo(\n    1\n  )"],
      "space_after_opener_is_consumed" => ["  { a: 1,\n    b: 2 }", "  {\n    a: 1,\n    b: 2\n  }"],
      "tabs_around_brackets_are_consumed" => ["  foo(\t1,\n    2\t)", "  foo(\n    1,\n    2\n  )"],
      "multibyte_text_does_not_shift_the_offsets" =>
      ["# \u20ac\nfoo( 1,\n  2 )", "# \u20ac\nfoo(\n  1,\n  2\n)"]
    }
  )
end
