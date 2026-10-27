# frozen_string_literal: true

RSpec.describe(RuboCop::Kata::NilAnswer) do
  include TabledCop

  let(:shipped) { RuboCop::ConfigLoader.default_configuration.for_cop("Elegant/NoNilReturn") }
  let(:cop) { RuboCop::Cop::Elegant::NoNilReturn.new(RuboCop::Config.new("Elegant/NoNilReturn" => shipped)) }

  # strong_migrations strips an error's cause before Rails prints it: `def e.cause; nil; end`.
  it "leaves an override of a core method whose contract answers nil" do
    source = "def error.cause\n  nil\nend\n\nclass Version\n  def <=>(other)\n    return nil unless other\n    " \
      "0\n  end\nend\n"
    expect(offenses(source)).to(be_empty)
  end

  it "still reports any other method's nil, and a block's" do
    source = "def error.reason\n  nil\nend\n\ndef find(id)\n  return nil unless id\n  1\nend\n\nrun { nil }\n"
    expect(offenses(source).map(&:line)).to(eq([2, 6, 10]))
  end
end
