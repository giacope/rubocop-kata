# frozen_string_literal: true

require "rubocop/kata/kit"

RSpec.describe(RuboCop::Kata::Kit) do
  def emit
    io = StringIO.new
    described_class.new(Dir.pwd, io: io).run.then { [io.string, it] }
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
    stub_const("#{described_class}::SOURCE", "/nowhere/SKILL.md")
    output, status = emit
    expect(output).to(eq("the gem ships no skill at /nowhere/SKILL.md\n"))
    expect(status).to(eq(1))
  end
end
