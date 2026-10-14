# frozen_string_literal: true

module RuboCop::Cop::Kata::Wording
  include RuboCop::Cop::Kata::Roster

  PATTERN_MSG = "`%s`: the segment `%s` does not match `Pattern`; a segment is one lowercase word."

  private

  def judge(range, name, stem)
    return if allowed?(name.to_s) || allowed?(stem)
    complaint = (yield if block_given?) || complaint(name, stem)
    add_offense(range, message: complaint) if complaint
  end

  def complaint(name, stem)
    words = stem.split("_")
    odd = words.find { !pattern.match?(it) }
    return format(PATTERN_MSG, name, odd) if odd
    count = core(words).size
    format(self.class::MSG, name, count, max, name) if count > max
  end

  def core(words)
    rest = listed?("Prefixes", words.first) ? words.drop(1) : words
    listed?("Suffixes", rest.last) ? rest[0..-2] : rest
  end

  def allowed?(name) = super || listed?("Terms", name)

  def max = Integer(cop_config.fetch("MaxWords", 2))

  def pattern = Regexp.new(cop_config.fetch("Pattern", "^[a-z][a-z0-9]{0,15}$"))
end
