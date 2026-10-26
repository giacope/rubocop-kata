# frozen_string_literal: true

require "rubocop/kata/nesting"

RSpec.describe(RuboCop::Kata::Nesting) do
  def definition(source, name)
    RuboCop::ProcessedSource.new(source, 3.4).ast.each_node(:class, :module).find { it.identifier.const_name == name }
  end

  let(:line) { definition("module Shop\n  module Cart\n    class Line; end\n  end\nend\n", "Line") }

  it "names the scopes around a definition, innermost first" do
    expect(described_class.new(line).names).to(eq(%w[Shop::Cart Shop]))
  end

  it "qualifies a definition by every scope around it" do
    expect(described_class.new(line).qualified).to(eq("Shop::Cart::Line"))
  end

  it "names each constant a reference could resolve to, innermost first" do
    expect(described_class.new(line).candidates("Item", absolute: false)).to(eq(%w[Shop::Cart::Item Shop::Item Item]))
  end

  it "names only the constant itself when the reference is absolute" do
    expect(described_class.new(line).candidates("Item", absolute: true)).to(eq(%w[Item]))
  end

  it "starts over at an absolute name" do
    ledger = definition("module Shop\n  class ::Ledger; end\nend\n", "Ledger")
    expect(described_class.new(ledger).qualified).to(eq("Ledger"))
  end
end
