# frozen_string_literal: true

RSpec.describe(RuboCop::Kata::SuccessToken) do
  include TabledCop

  let(:cop) { RuboCop::Cop::Naming::PredicateMethod.new(RuboCop::Config.new) }
  let(:command) { "acts, then answers a boolean: a command returns nothing (or `self`)" }

  before { skip("RuboCop #{RuboCop::Version::STRING} has no Naming/PredicateMethod") unless cop_class }

  def cop_class = defined?(RuboCop::Cop::Naming::PredicateMethod)

  def messages(source) = offenses(source).map { [it.line, it.message.delete_prefix("Naming/PredicateMethod: ")] }

  # ferrum's `def clear; @headers = {}; true; end`: `clear?` would be a query that changes state.
  it "tells a command that answers a boolean to return nothing, not to take a `?`" do
    source = "def clear\n  @headers = {}\n  true\nend\ndef activate\n  command(:activate)\n  true\nend\n" \
      "def load(path)\n  rows = read(path)\n  rows.each { add(it) }\n  true\nend\n" \
      "def bump\n  @count += 1\n  true\nend\n"
    expect(messages(source)).to(eq([1, 5, 9, 14].map { [it, format(described_class::COMMAND, name(source, it))] }))
  end

  it "tells a command that waits, or acts in a branch, the same, whatever it answers" do
    source = "def wait_for_idle(timeout)\n  start = clock\n  until idle?\n    return false if late?(start)\n    " \
      "pause\n  end\n  true\nend\ndef add_tag(url)\n  if url\n    evaluate(url)\n  end\n  true\nend\n" \
      "def register(item)\n  case item\n  when Module\n    add(item)\n  end\n  true\nend\n" \
      "def flush\n  begin\n    $count = 0\n  end\n  true\nend\n"
    expect(messages(source).select { |_, text| text.include?(command) }.map(&:first)).to(eq([1, 9, 15, 22]))
  end

  # savon's `equals_except_any`, state_machines' `check_state`: guards, a search loop and a cache compute the answer.
  it "keeps RuboCop's advice for a method whose statements only compute its answer" do
    source = "def ready\n  total = @items.size\n  total += 1\n  return false unless total.positive?\n  " \
      "return true if total > 9\n  true\nend\ndef enabled = true\ndef busy\n  @jobs.any?\nend\n" \
      "def same(left, right)\n  raise Error, \"none\" unless left\n  @seen ||= {}\n  left.each do |key, value|\n    " \
      "next if value == :any\n    return false if value != right[key]\n  end\n  true\nend\n"
    expect(messages(source)).to(eq([1, 8, 9, 12].map { [it, "Predicate method names should end with `?`."] }))
  end

  it "leaves RuboCop's other advice as it is" do
    source = "def done?\n  @x = 1\n  5\nend\n"
    expect(messages(source)).to(eq([[1, "Non-predicate method names should not end with `?`."]]))
  end

  def name(source, line) = source.lines[line - 1][/def (\w+)/, 1]
end
