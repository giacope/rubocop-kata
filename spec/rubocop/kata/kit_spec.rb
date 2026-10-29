# frozen_string_literal: true

require "rubocop/kata/kit"

RSpec.describe(RuboCop::Kata::Kit) do
  def emit(source: described_class::SOURCE)
    io = StringIO.new
    kit = described_class.new(Dir.pwd, io: io, source: source)
    kit.run
    [io.string, kit.status]
  end

  it "prints a skill an agent can route on", :aggregate_failures do
    output, status = emit
    expect(output).to(start_with("---\nname: rubocop-kata\n"))
    expect(status).to(eq(0))
  end

  it "prints the skill verbatim, so redirecting it yields the shipped file" do
    expect(emit.first).to(eq(File.read(described_class::SOURCE)))
  end

  it "says where it looked when the skill is missing", :aggregate_failures do
    output, status = emit(source: "/nowhere/SKILL.md")
    expect(output).to(eq("the gem ships no skill at /nowhere/SKILL.md\n"))
    expect(status).to(eq(1))
  end
end
