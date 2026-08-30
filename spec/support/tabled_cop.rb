# frozen_string_literal: true

module TabledCop
  def offenses(source)
    RuboCop::Cop::Commissioner.new([cop], [], raise_error: true).investigate(processed(source)).offenses
  end

  def autocorrect(source)
    parsed = processed(source)
    found = RuboCop::Cop::Commissioner.new([cop], [], raise_error: true).investigate(parsed).offenses
    corrector = RuboCop::Cop::Corrector.new(parsed)
    found.each { corrector.merge!(it.corrector) unless it.corrector.nil? }
    corrector.process
  end

  def processed(source) = RuboCop::ProcessedSource.new(source, 3.4)
end

RSpec.shared_examples "tabled cop" do |allowed:, violations:, corrections: {}|
  include TabledCop

  allowed.each do |name, source|
    it("allows #{name.tr("_", " ")}") { expect(offenses(source)).to(be_empty) }
  end

  violations.each do |name, (source, count)|
    it("rejects #{name.tr("_", " ")}") { expect(offenses(source).size).to(eq(count)) }
  end

  corrections.each do |name, (source, expected)|
    it("corrects #{name.tr("_", " ")}") { expect(autocorrect(source)).to(eq(expected)) }
  end
end
