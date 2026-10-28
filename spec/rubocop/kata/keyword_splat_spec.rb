# frozen_string_literal: true

RSpec.describe(RuboCop::Kata::KeywordSplat) do
  include TabledCop

  let(:style) { { "EnforcedStyle" => "with_fixed_indentation" } }
  let(:hash) { {} }
  let(:config) { RuboCop::Config.new("Layout/ArgumentAlignment" => style, "Layout/HashAlignment" => hash) }
  let(:cop) { RuboCop::Cop::Layout::ArgumentAlignment.new(config) }
  let(:source) { "broadcast(\n  *streamables,\n**extract(rendering),\n  target: self,\n    **more\n)\n" }

  def processed(source) = RuboCop::ProcessedSource.new(source, 3.4).tap { it.config = config }

  # turbo-rails: `-a` broke a call before its double splat and no cop indented the new line.
  it "indents a double splat in a braceless last hash, among its pairs" do
    fixed = "broadcast(\n  *streamables,\n  **extract(rendering),\n  target: self,\n  **more\n)\n"
    expect([offenses(source).map(&:line), autocorrect(source)]).to(eq([[3, 5], fixed]))
  end

  it "leaves the hash to HashAlignment when it aligns separators" do
    hash.replace("EnforcedColonStyle" => "separator")
    expect(offenses(source).map(&:line)).to(be_empty)
  end

  it "leaves a braced hash and a call without a hash to the cop" do
    braced = "broadcast(\n  *streamables,\n{ **extract(rendering) }\n)\n\nrun(\n  a,\nb\n)\n"
    expect(offenses(braced).map(&:line)).to(eq([3, 8]))
  end
end
