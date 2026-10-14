# frozen_string_literal: true

class Lexicography::Synset
  AGENTIVE = %w[05 06 10 14 18 19 27].freeze
  PERSON = "18"

  def initialize(line)
    @line = line
  end

  def person? = fields[1] == PERSON

  def lexical? = AGENTIVE.include?(fields[1])

  def words = (0...count).map { fields[4 + (2 * it)].downcase }

  def derived(word)
    position = words.index(word)
    return [] unless position
    pointers.select { |symbol, _, kind, link| symbol == "+" && kind == "v" && link[0, 2].to_i(16) == position + 1 }
      .map { |_, offset, _, link| [offset, link[2, 2].to_i(16) - 1] }
  end

  def glossed?(verb) = (forms(verb) - words).any? { gloss.match?(/\b#{Regexp.escape(it)}\b/i) }

  private

  def fields = @_fields ||= @line.split(" | ", 2).first.split

  def gloss = @line.split(" | ", 2).last.to_s

  def count = fields[3].to_i(16)

  def pointers
    start = 5 + (2 * count)
    fields[start..].each_slice(4).first(fields[start - 1].to_i)
  end

  def forms(verb)
    [
      verb, "#{verb}s", "#{verb}es", "#{verb}d", "#{verb}ed", "#{verb}ing", *(verb.end_with?("e") ? silent(verb) : []),
      *(verb.match?(/[^aeiou][aeiou][b-df-hj-np-tv-z]\z/) ? doubled(verb) : []),
      *(verb.end_with?("y") ? [verb.sub(/y\z/, "ies"), verb.sub(/y\z/, "ied")] : [])
    ]
  end

  def silent(verb) = [verb.sub(/e\z/, "ing"), verb.sub(/e\z/, "ed")]

  def doubled(verb) = ["#{verb}#{verb[-1]}ing", "#{verb}#{verb[-1]}ed"]
end
