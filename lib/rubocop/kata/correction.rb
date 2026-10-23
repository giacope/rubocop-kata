# frozen_string_literal: true

class RuboCop::Kata::Correction
  def initialize(original, corrected)
    @original = original
    @corrected = corrected
  end

  def flaw
    before = Prism.parse(@original)
    return unless before.success?
    after = Prism.parse(@corrected)
    return "made it unparsable" unless after.success?
    line = change(literals(before), literals(after))
    "changed the literal on line #{line}" if line
  end

  private

  def change(before, after) = before.unmatched(after) || after.unmatched(before)

  def literals(parsed) = RuboCop::Kata::Literals.new(parsed.value)
end
