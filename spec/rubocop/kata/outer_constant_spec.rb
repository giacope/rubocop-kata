# frozen_string_literal: true

RSpec.describe(RuboCop::Kata::OuterConstant) do
  include TabledCop

  let(:cop) { RuboCop::Cop::Lint::SelfAssignment.new(RuboCop::Config.new) }

  # dry-monads' `Lazy = Lazy` inside `class Lazy; module Mixin`: Mixin::Lazy names the outer Dry::Monads::Lazy.
  it "reads an unqualified constant copied into a nested namespace as the outer one, not a self-assignment" do
    nested = "module Demo\n  class Lazy\n    module Mixin\n      Lazy = Lazy\n    end\n  end\nend\n"
    singleton = "class Demo\n  class << self\n    Unit = Unit\n  end\nend\n"
    expect(offenses(nested + singleton)).to(be_empty)
  end

  it "still reports a constant assigned itself where no namespace encloses it, or by its qualified name" do
    source = "Lazy = Lazy\nconfigure do\n  Unit = Unit\nend\nmodule Demo\n  Demo::Lazy = Demo::Lazy\n  " \
      "::Unit = ::Unit\n  @x = @x\nend\n"
    expect(offenses(source).map(&:line)).to(eq([1, 3, 6, 7, 8]))
  end
end
