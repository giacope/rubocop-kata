# frozen_string_literal: true

RSpec.describe(RuboCop::Kata::Variable::Boundary) do
  def crossed?(source)
    body = RuboCop::ProcessedSource.new(source, 3.4).ast
    read = body.each_node(:lvar).find { it.children.first == :sum }
    described_class.new(body.each_node(:lvasgn).first, read).crossed?
  end

  it "takes a read outside the scope that holds the assignment as crossed" do
    expect(crossed?("def total(flag)\n  if flag\n    sum = 1\n  end\n  report(sum)\nend\n")).to(be(true))
  end

  it "takes a read in a later statement of the same body as reachable" do
    expect(crossed?("def total\n  sum = 1\n  report(sum)\nend\n")).to(be(false))
  end
end
