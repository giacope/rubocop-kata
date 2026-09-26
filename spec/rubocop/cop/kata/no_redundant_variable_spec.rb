# frozen_string_literal: true

require "timeout"
# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT
# Derived from rubocop-elegant (https://github.com/yegor256/rubocop-elegant), see LICENSE.txt

RSpec.describe(RuboCop::Cop::Kata::NoRedundantVariable) do
  include TabledCop

  let(:cop) { described_class.new(RuboCop::Config.new) }

  it_behaves_like(
    "tabled cop", allowed: {
      "variable_used_twice" => "def foo\n  x = bar\n  baz(x)\n  qux(x)\nend",
      "variable_reassigned_then_read" => "def foo\n  x = 1\n  x = 2\n  baz(x)\nend",
      "compound_plus_assignment" => "def foo\n  x = 0\n  arr.each { |e| x += e }\n  x\nend",
      "or_assign_modification" => "def foo\n  x = nil\n  x ||= compute\n  bar(x)\nend",
      "method_argument_used_once" => "def foo(x); bar(x); end",
      "block_argument_used_once" => "def foo\n  arr.each { |e| bar(e) }\nend",
      "assignment_in_if_condition" => "def foo\n  if (x = bar)\n    baz(x)\n  end\nend",
      "assignment_in_while_condition" => "def foo\n  while (line = readline)\n    puts(line)\n  end\nend",
      "multiple_assignment" => "def foo\n  a, b = pair\n  a + b\nend",
      "rescue_exception_variable" => "def foo\n  bar\nrescue => e\n  log(e)\nend",
      "for_loop_iterator" => "def foo\n  for x in arr\n    bar(x)\n  end\nend",
      "variable_assigned_never_read" => "def foo\n  x = expensive\n  bar\nend",
      "class_method_two_reads" => "def self.foo\n  x = bar\n  baz(x)\n  qux(x)\nend",
      "no_local_variables" => "def foo\n  bar\n  baz\nend",
      "empty_body" => "def foo\nend",
      "variable_modified_via_send" => "def foo\n  x = []\n  x << 1\n  x\nend",
      "read_inside_block_loop" => "def foo\n  x = compute\n  arr.each { |e| bar(x, e) }\nend",
      "read_inside_while_loop" => "def foo\n  x = compute\n  while cond\n    bar(x)\n  end\nend",
      "read_inside_until_loop" => "def foo\n  x = compute\n  until cond\n    bar(x)\n  end\nend",
      "read_inside_for_loop" => "def foo\n  x = compute\n  for e in arr\n    bar(x, e)\n  end\nend",
      "read_inside_nested_block" => "def foo\n  x = compute\n  arr.each { |a| a.each { |b| bar(x, b) } }\nend",
      "assigned_in_block_read_outside" => "def foo\n  x = nil\n  arr.each { |e| x = e }\n  bar(x)\nend",
      "read_inside_if_branch" => "def foo\n  x = compute\n  bar(x) if cond\nend",
      "read_inside_full_if_then_branch" => "def foo\n  x = compute\n  if cond\n    bar(x)\n  end\nend",
      "read_inside_if_else_branch" => "def foo\n  x = compute\n  if cond\n    bar\n  else\n    bar(x)\n  end\nend",
      "read_inside_case_when_branch" => "def foo\n  x = compute\n  case y\n  when 1\n    bar(x)\n  end\nend",
      "read_inside_case_match_in_branch" => "def foo\n  x = compute\n  case y\n  in 1\n    bar(x)\n  end\nend",
      "read_inside_and_rhs" => "def foo\n  x = compute\n  cond && bar(x)\nend",
      "read_inside_or_rhs" => "def foo\n  x = compute\n  cond || bar(x)\nend",
      "read_inside_rescue_body" => "def foo\n  x = compute\n  bar\nrescue\n  baz(x)\nend",
      "read_inside_ensure" => "def foo\n  x = compute\n  bar\nensure\n  baz(x)\nend",
      "call_between_assignment_and_read" => "def foo\n  line = receive\n  reader.close\n  bar(line)\nend",
      "mutation_between_assignment_and_read" => "def foo\n  touched = ledger.uniq\n  ledger.clear\n  touched\nend",
      "timed_call_between_assignment_and_read" => "def foo\n  started = monotonic\n  bar\n  monotonic - started\nend",
      "yield_read_after_other_work" => "def foo\n  returned = yield\n  log(out)\n  returned\nend",
      "calls_before_read_in_same_array" => "def foo\n  returned = yield\n  [out.string, err.string, returned]\nend",
      "call_before_read_in_same_argument_list" => "def foo\n  x = bar\n  baz(qux, x)\nend",
      "local_assignment_that_changes_saved_value" =>
      "def foo\n  state = :old\n  saved = state\n  state = :new\n  saved\nend",
      "constant_lookup_between_assignment_and_read" =>
      "def foo\n  saved = $state\n  Trigger::Value\n  saved\nend",
      "instance_variable_operand_before_read" => "def foo\n  x = bump\n  bar(@n, x)\nend",
      "global_variable_operand_before_read" => "def foo\n  x = bump\n  bar($n, x)\nend",
      "class_variable_operand_before_read" => "def foo\n  x = bump\n  bar(@@n, x)\nend",
      "constant_operand_before_read" => "def foo\n  x = bump\n  bar(CONST, x)\nend",
      "back_reference_operand_before_read" => "def foo\n  x = (s =~ /a/)\n  bar($~, x)\nend",
      "instance_variable_inside_array_before_read" => "def foo\n  x = bump\n  bar([@n], x)\nend",
      "chained_assignments_read_in_separate_statements" =>
      "def foo\n  a = one\n  b = two\n  bar(a)\n  baz(b)\nend",
      "compound_assignment_after_read" => "def foo\n  x = compute\n  bar(x, x += 1)\nend",
      "or_assignment_after_read" => "def foo\n  x = compute\n  bar(x, x ||= 1)\nend",
      "and_assignment_after_read" => "def foo\n  x = compute\n  bar(x, x &&= 1)\nend",
      "read_inside_endless_while_loop" => "def foo\n  x = compute\n  while true\n    bar(x)\n  end\nend",
      "read_inside_rescue_of_pure_begin" =>
      "def foo\n  x = compute\n  begin\n    1\n  rescue\n    bar(x)\n  end\nend",
      "assigned_inside_begin_block_read_after" =>
      "def foo\n  begin\n    x = compute\n    1\n  end\n  bar(x)\nend"
    }, violations: {
      "simple_inlinable" => ["def foo\n  x = bar\n  baz(x)\nend", 1],
      "class_method_inlinable" => ["def self.foo\n  x = bar\n  baz(x)\nend", 1],
      "inlinable_inside_block" =>
      ["def foo\n  arr.each do |e|\n    y = e.bar\n    baz(y)\n  end\nend", 1],
      "multiple_redundant_in_one_method" =>
      ["def foo\n  a = one\n  b = two\n  bar(a, b)\nend", 2],
      "inlinable_with_rescue" =>
      ["def foo\n  x = bar\n  baz(x)\nrescue StandardError\n  retry\nend", 1],
      "each_def_has_own_redundant" =>
      ["def foo\n  x = bar\n  baz(x)\nend\ndef qux\n  y = bar\n  baz(y)\nend", 2],
      "inlinable_returned_directly" => ["def foo\n  x = compute\n  x\nend", 1],
      "inlinable_inside_if_branch" =>
      ["def foo\n  if cond\n    x = bar\n    baz(x)\n  end\nend", 1],
      "read_in_if_condition_position" =>
      ["def foo\n  x = bar\n  baz if x.empty?\nend", 1],
      "read_in_and_lhs_position" =>
      ["def foo\n  x = bar\n  baz(x) && qux\nend", 1],
      "read_in_case_subject_position" =>
      ["def foo\n  x = bar\n  case x\n  when 1\n    one\n  end\nend", 1],
      "pure_statement_between_assignment_and_read" =>
      ["def foo\n  x = bar\n  1\n  baz(x)\nend", 1],
      "rational_literal_between_assignment_and_read" =>
      ["def foo\n  x = bar\n  1r\n  baz(x)\nend", 1],
      "complex_literal_between_assignment_and_read" =>
      ["def foo\n  x = bar\n  1i\n  baz(x)\nend", 1],
      "inclusive_range_between_assignment_and_read" =>
      ["def foo\n  x = bar\n  1..2\n  baz(x)\nend", 1],
      "exclusive_range_between_assignment_and_read" =>
      ["def foo\n  x = bar\n  1...2\n  baz(x)\nend", 1],
      "pure_operands_before_read" =>
      ["def foo\n  x = bar\n  baz(1, [2], x)\nend", 1],
      "self_operand_before_read" =>
      ["def foo\n  x = bar\n  baz(self, x)\nend", 1],
      "local_operand_before_read" =>
      ["def foo(y)\n  x = bar\n  baz(y, x)\nend", 1],
      "read_inside_another_redundant_assignment" =>
      ["def foo\n  a = one\n  b = [a]\n  bar(b)\nend", 2],
      "call_after_read_in_same_argument_list" =>
      ["def foo\n  x = bar\n  baz(x, qux)\nend", 1],
      "chained_assignments_read_out_of_order" =>
      ["def foo\n  a = one\n  b = two\n  bar(b, a)\nend", 1],
      "assignments_ahead_of_an_inner_def" =>
      ["def foo\n  x = 1\n  qux(x)\n  def bar\n    x = 2\n    baz(x)\n  end\nend", 2],
      "assignments_ahead_of_an_inner_singleton_def" =>
      ["def foo\n  x = 1\n  qux(x)\n  def self.bar\n    x = 2\n    baz(x)\n  end\nend", 2],
      "assignment_after_a_parenthesised_condition_assignment" =>
      ["def foo\n  if (x = bar)\n    1\n  end\n  x = 2\n  baz(x)\nend", 1],
      "multi_line_assignment" => ["def foo\n  x = [\n    1\n  ]\n  baz(x)\nend", 1]
    }, corrections: {
      "send_call_inlines_unwrapped" =>
      ["def foo\n  x = bar\n  baz(x)\nend", "def foo\n  baz(bar)\nend"],
      "integer_literal_inlines_unwrapped" =>
      ["def foo\n  x = 42\n  baz(x)\nend", "def foo\n  baz(42)\nend"],
      "returned_directly_inlines" =>
      ["def foo\n  x = compute\n  x\nend", "def foo\n  compute\nend"],
      "binary_operator_wrapped_in_parens" =>
      ["def foo\n  x = a + b\n  baz(x)\nend", "def foo\n  baz((a + b))\nend"],
      "ternary_wrapped_in_parens" =>
      ["def foo\n  x = cond ? a : b\n  baz(x)\nend", "def foo\n  baz((cond ? a : b))\nend"],
      "hash_literal_with_braces_inlines_unwrapped" =>
      ["def foo\n  x = { a: 1 }\n  baz(x)\nend", "def foo\n  baz({ a: 1 })\nend"],
      "method_with_receiver_no_args_inlines_unwrapped" =>
      ["def foo\n  x = a.b\n  baz(x)\nend", "def foo\n  baz(a.b)\nend"],
      "inside_block_inlines" => [
        "def foo\n  arr.each do |e|\n    y = e.bar\n    baz(y)\n  end\nend",
        "def foo\n  arr.each do |e|\n    baz(e.bar)\n  end\nend"
    ],
      "multiple_redundant_inline_together" =>
      ["def foo\n  a = one\n  b = two\n  bar(a, b)\nend", "def foo\n  bar(one, two)\nend"],
      "class_method_inlines" =>
      ["def self.foo\n  x = bar\n  baz(x)\nend", "def self.foo\n  baz(bar)\nend"],
      "shared_line_assignment_is_left_alone" =>
      ["def foo\n  x = bar; baz(x)\nend", "def foo\n  x = bar; baz(x)\nend"],
      "call_between_assignment_and_read_is_left_alone" => [
        "def foo\n  line = receive\n  reader.close\n  bar(line)\nend",
        "def foo\n  line = receive\n  reader.close\n  bar(line)\nend"
    ],
      "calls_before_read_in_array_are_left_alone" => [
        "def foo\n  returned = yield\n  [out.string, returned]\nend",
        "def foo\n  returned = yield\n  [out.string, returned]\nend"
    ],
      "read_inside_another_redundant_assignment_inlines_the_inner_one" => [
        "def foo\n  a = one\n  b = [a]\n  bar(b)\nend",
        "def foo\n  b = [one]\n  bar(b)\nend"
    ],
      "instance_variable_operand_before_read_is_left_alone" => [
        "def foo\n  x = bump\n  bar(@n, x)\nend",
        "def foo\n  x = bump\n  bar(@n, x)\nend"
    ],
      "hash_into_bare_send_arg_is_wrapped" =>
      ["def foo\n  x = { a: 1 }\n  baz x\nend", "def foo\n  baz ({ a: 1 })\nend"],
      "shorthand_pair_expands_to_long_form" =>
      ["def foo\n  ids = compute\n  bar(ids:)\nend", "def foo\n  bar(ids: compute)\nend"],
      "shorthand_pair_in_hash_literal_expands" =>
      ["def foo\n  ids = compute\n  bar({ ids: })\nend", "def foo\n  bar({ ids: compute })\nend"],
      "long_form_pair_still_inlines_the_value_only" =>
      ["def foo\n  ids = compute\n  bar(list: ids)\nend", "def foo\n  bar(list: compute)\nend"],
      "hash_rocket_pair_keeps_its_key" =>
      ["def foo\n  ids = compute\n  bar(\"ids\" => ids)\nend", "def foo\n  bar(\"ids\" => compute)\nend"],
      "parenthesised_expression_is_not_wrapped_again" =>
      ["def foo\n  x = (a + b)\n  baz(x)\nend", "def foo\n  baz((a + b))\nend"],
      "defined_check_is_wrapped" =>
      ["def foo\n  x = defined?(a)\n  baz(x)\nend", "def foo\n  baz((defined?(a)))\nend"],
      "hash_returned_directly_inlines_unwrapped" =>
      ["def foo\n  x = { a: 1 }\n  x\nend", "def foo\n  { a: 1 }\nend"],
      "hash_into_pair_value_inlines_unwrapped" =>
      ["def foo\n  x = { a: 1 }\n  bar(key: x)\nend", "def foo\n  bar(key: { a: 1 })\nend"],
      "multi_line_assignment_is_left_alone" => [
        "def foo\n  x = [\n    1\n  ]\n  baz(x)\nend",
        "def foo\n  x = [\n    1\n  ]\n  baz(x)\nend"
    ],
      "bare_read_inside_another_redundant_assignment_inlines_the_inner_one" =>
      ["def foo\n  a = one\n  b = a\n  bar(b)\nend", "def foo\n  b = one\n  bar(b)\nend"]
    }
  )

  it "names the redundant variable" do
    expect(offenses("def foo\n  greeting = 'hi'\n  puts(greeting)\nend").first.message).to(include('"greeting"'))
  end

  it "keeps an inner def out of the outer scope" do
    source = "def foo\n  x = 1\n  def bar\n    x = 2\n    baz(x)\n  end\n  qux(x)\n  zap(x)\nend"
    expect(offenses(source).size).to(eq(1))
  end

  it "scales to a long chain of assignments" do
    assignments = (1..20).map { "  a#{it} = f#{it}" }
    arguments = (1..20).map { "a#{it}" }.join(", ")
    source = ["def foo", *assignments, "  sink(#{arguments})", "end"].join("\n")
    expect(Timeout.timeout(2) { offenses(source).size }).to(eq(20))
  end
end
