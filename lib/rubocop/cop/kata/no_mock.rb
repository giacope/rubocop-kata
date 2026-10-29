# frozen_string_literal: true

class RuboCop::Cop::Kata::NoMock < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Ownership

  MSG = "`%s` %s, so the test knows which calls the object makes; pass a fake instead, a small " \
    "working object with the collaborator's interface."
  BUILT = "builds a mock"
  STUBBED = "stubs a message"
  EXPECTED = "expects a message"
  DOUBLES = %i[double instance_double class_double object_double spy instance_spy class_spy object_spy].freeze
  MATCHERS = %i[receive receive_messages receive_message_chain have_received].freeze
  TARGETS = {
    allow: STUBBED, allow_any_instance_of: STUBBED, expect: EXPECTED, expect_any_instance_of: EXPECTED,
    is_expected: EXPECTED
  }.freeze
  SENT = {
    stub: STUBBED, stubs: STUBBED, stub_chain: STUBBED, expects: EXPECTED, should_receive: EXPECTED,
    should_not_receive: EXPECTED
  }.freeze
  BUILDERS = [*DOUBLES, :stub_everything, :mock, :stub].freeze

  def_node_matcher :minitest_mock?, "(send (const (const {nil? cbase} {:Minitest :MiniTest}) :Mock) :new ...)"
  def_node_matcher :let, "(send nil? {:let :let! :subject :subject!} (sym $_) ...)"
  def_node_matcher :expectation, <<~PATTERN
    (send (send nil? ${#{TARGETS.keys.map(&:inspect).join(" ")}} ...) {:to :not_to :to_not} $_ ...)
  PATTERN

  def on_send(node)
    kinds(node).each { add_offense(node, message: format(MSG, label(node), it)) }
  end

  private

  def kinds(node)
    return [BUILT] if minitest_mock?(node)
    return sent(node) if node.receiver
    BUILDERS.include?(node.method_name) ? built(node) : matched(node)
  end

  def built(node)
    name = node.method_name
    answered?(name) || processed_source.ast.each_node(:send).any? { let(it) == name } ? [] : [BUILT]
  end

  def matched(node)
    runner = node.each_ancestor(:send).find { expectation(it) } if MATCHERS.include?(node.method_name)
    found =
      expectation(runner) do |target, matcher|
        TARGETS.fetch(target) if matcher.each_node(:send).any? { it.equal?(node) }
      end
    found ? [found] : []
  end

  def sent(node)
    name = node.method_name
    SENT.key?(name) && node.arguments? && !answered?(name) ? [SENT.fetch(name)] : []
  end

  def label(node) = minitest_mock?(node) ? node.receiver.source : node.method_name.to_s
end
