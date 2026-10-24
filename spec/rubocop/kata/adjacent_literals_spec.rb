# frozen_string_literal: true

RSpec.describe(RuboCop::Kata::AdjacentLiterals) do
  include TabledCop

  let(:cop) do
    setting = { "Layout/LineLength" => { "Max" => 120 }, "Layout/RedundantLineBreak" => { "InspectBlocks" => false } }
    RuboCop::Cop::Layout::RedundantLineBreak.new(RuboCop::Config.new(setting))
  end

  # `GREETING = 'Hello, ' \ "world"` became `"Hello, " + "world"`, a new unfrozen String.
  it "joins no line whose break sits between adjacent string literals, and every other line it would" do
    source = "a = 'b' \\\n  \"c\"\nd = \"e\" \\\n  \"f\"\ng(1,\n  2)\nh('i' \"j\",\n  3)\nk(4, # four\n  5)\n"
    expect(offenses(source).map(&:line)).to(eq([5, 7]))
  end
end
