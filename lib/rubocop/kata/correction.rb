# frozen_string_literal: true

class RuboCop::Kata::Correction
  def initialize(original, corrected)
    @original = original
    @corrected = corrected
  end

  def flaws
    before = Prism.parse(@original)
    return [] unless before.success?
    after = Prism.parse(@corrected)
    return ["made it unparsable"] unless after.success?
    changes(literals(before), literals(after)).map { "changed the literal on line #{it}" }
  end

  private

  def changes(before, after) = before.unmatched(after).then { it.empty? ? after.unmatched(before) : it }

  def literals(parsed) = RuboCop::Kata::Literals.new(parsed.value)
end
