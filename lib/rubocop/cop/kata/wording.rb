# frozen_string_literal: true

module RuboCop::Cop::Kata::Wording
  include RuboCop::Cop::Kata::Roster

  private

  def good?(stem)
    words = stem.split("_")
    return false unless words.all? { pattern.match?(it) }
    count = core(words).size
    return words.one? if count == words.size
    count.between?(1, max)
  end

  def core(words)
    rest = listed?("Prefixes", words.first) && words.size > 1 ? words.drop(1) : words
    listed?("Suffixes", rest.last) && rest.size > 1 ? rest[0..-2] : rest
  end

  def allowed?(name) = super || listed?("Terms", name)

  def max = Integer(cop_config.fetch("MaxWords", 2))

  def pattern = Regexp.new(cop_config.fetch("Pattern", "^[a-z][a-z0-9]{0,15}$"))
end
