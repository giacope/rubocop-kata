# frozen_string_literal: true

module RuboCop::Cop::Kata::AgentNoun
  DOER_MSG = "`%s` names a doer; name the %s for the thing it is, not the work it does."
  DOER_HINT = "#{DOER_MSG} Try `%s`.".freeze
  SEGMENT = /[A-Z]+\d*(?=[A-Z][a-z]|\z)|[A-Z][a-z0-9]*/
  DERIVATIONS = [[/ator\z/, "ation"], [/ector\z/, "ection"], [/isor\z/, "ision"], [/i[zs]er\z/, "is"]].freeze
  DICTIONARY = RuboCop::Kata::Dictionary.new
  private_constant :DICTIONARY

  private

  def doer?(name) = RuboCop::Kata::Agency.new(segments(name).last.to_s.downcase).doer?

  def doer(name, kind)
    hint = suggestion(name)
    hint ? format(DOER_HINT, name, kind, hint) : format(DOER_MSG, name, kind)
  end

  def suggestion(name)
    head, tail = split(name)
    DERIVATIONS.filter_map { |pattern, noun| proposal(head + tail.sub(pattern, noun)) if pattern.match?(tail) }.first
  end

  def split(name)
    segments = segments(name)
    [segments[0..-2].join, segments.last.to_s]
  end

  def proposal(name) = (name if known?(name))

  def known?(name) = DICTIONARY.entry?(segments(name).last.to_s.downcase)

  def segments(name) = name.scan(Regexp.union(*brands, SEGMENT))

  def brands
    Hash(config.for_cop("RSpec/SpecFilePathFormat")["CustomTransform"])
      .filter_map { |brand, word| brand if word.to_s.match?(/\A[a-z0-9]+\z/) }
  end
end
