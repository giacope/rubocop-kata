# frozen_string_literal: true

module RuboCop::Cop::Kata::AgentNoun
  DOER_MSG = "`%s` names a doer; name the %s for the thing it is, not the work it does."
  DOER_HINT = "#{DOER_MSG} Try `%s`.".freeze
  DOER = /(?:er|or)\z/
  SEGMENT = /[A-Z]+(?=[A-Z][a-z]|\z)|[A-Z][a-z0-9]*/
  DERIVATIONS = [[/ator\z/, "ation"], [/ector\z/, "ection"], [/isor\z/, "ision"], [/i[zs]er\z/, "is"]].freeze

  private

  def doer?(name) = DOER.match?(name)

  def doer(name)
    hint = suggestion(name)
    hint ? format(DOER_HINT, name, kind, hint) : format(DOER_MSG, name, kind)
  end

  def suggestion(name)
    head, tail = split(name)
    DERIVATIONS.filter_map { proposal(head + tail.sub(it.first, it.last)) }.first
  end

  def split(name)
    segments = name.scan(SEGMENT)
    [segments[0..-2].join, segments.last.to_s]
  end

  def proposal(name)
    return if name.empty? || DOER.match?(name)
    return unless known?(name)
    name
  end

  def known?(name) = RuboCop::Kata::Dictionary::ENTRIES.include?(name.scan(SEGMENT).last.to_s.downcase)
end
