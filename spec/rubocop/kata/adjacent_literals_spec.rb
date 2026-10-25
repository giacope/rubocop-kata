# frozen_string_literal: true

RSpec.describe(RuboCop::Kata::AdjacentLiterals) do
  include TabledCop

  let(:cop) do
    setting = { "Layout/LineLength" => { "Max" => 120 }, "Layout/RedundantLineBreak" => { "InspectBlocks" => false } }
    RuboCop::Cop::Layout::RedundantLineBreak.new(RuboCop::Config.new(setting))
  end
  let(:source) { "a = 'b' \\\n  \"c\"\nd = \"e\" \\\n  \"f\"\ng(1,\n  2)\nh('i' \"j\",\n  3)\nk(4, # four\n  5)\n" }

  it "still reports a line break between adjacent string literals" do
    expect(offenses(source).map(&:line)).to(eq([1, 3, 5, 7]))
  end

  # `GREETING = 'Hello, ' \ "world"` became `"Hello, " + "world"`, a new unfrozen String.
  it "never joins adjacent string literals across their line break, and joins every other line it would" do
    joined = "a = 'b' \\\n  \"c\"\nd = \"e\" \\\n  \"f\"\ng(1, 2)\nh('i' \"j\", 3)\nk(4, # four\n  5)\n"
    expect(autocorrect(source)).to(eq(joined))
  end
end
