# frozen_string_literal: true

class RuboCop::Cop::Kata::AgentNoun < RuboCop::Cop::Base
  MSG = "`%s` names a doer; name the class for the thing it is, not the work it does."
  HINT = "#{MSG} Try `%s`.".freeze
  SUFFIX = /(?:er|or)\z/
  SEGMENT = /[A-Z]+(?=[A-Z][a-z]|\z)|[A-Z][a-z0-9]*/
  DERIVATIONS = [[/ator\z/, "ation"], [/ector\z/, "ection"], [/isor\z/, "ision"], [/i[zs]er\z/, "is"]].freeze

  def on_class(node) = check(node)

  def on_module(node) = check(node)

  private

  def check(node)
    name = node.identifier.short_name.to_s
    return unless SUFFIX.match?(name)
    return if allowed?(name)
    add_offense(node.identifier, message: message(name))
  end

  def message(name)
    hint = suggestion(name)
    hint ? format(HINT, name, hint) : format(MSG, name)
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
    return if name.empty? || SUFFIX.match?(name)
    return unless known?(name)
    name
  end

  def known?(name) = RuboCop::Kata::Dictionary::ENTRIES.include?(name.scan(SEGMENT).last.to_s.downcase)

  def allowed?(name) = list.any? { name.end_with?(it) }

  def list = Array(cop_config["AllowedNames"]).map(&:to_s).reject(&:empty?)
end
