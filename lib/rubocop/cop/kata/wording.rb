# frozen_string_literal: true

module RuboCop::Cop::Kata::Wording
  include RuboCop::Cop::Kata::Roster

  PATTERN_MSG = "`%s`: the segment `%s` does not match `Pattern`; a segment is one lowercase word."

  private

  def judge(range, name, stem, chained = [])
    return if allowed?(name.to_s) || allowed?(stem)
    (chained.empty? ? complaints(name, stem) : chained).each { add_offense(range, message: it) }
  end

  def complaints(name, stem)
    words = stem.split("_")
    odd = words.grep_v(pattern)
    return [format(PATTERN_MSG, name, odd.first)] unless odd.empty?
    count = core(words).size
    count > max ? [format(self.class::MSG, name, count, max, name)] : []
  end

  def core(words)
    root = namespaces.find { |segments| words.first(segments.size) == segments }
    rest = root ? words.drop(root.size) : prefixed(words)
    listed?("Suffixes", rest.last) ? rest[0..-2] : rest
  end

  def prefixed(words) = listed?("Prefixes", words.first) ? words.drop(1) : words

  def namespaces = @_namespaces ||= list("Roots").flat_map { [segmented(it), it.downcase.split("::")] }

  def segmented(root) = root.gsub("::", "_").gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase.split("_")

  def allowed?(name) = super || listed?("Terms", name) || list("AllowedPatterns").any? { name.match?(Regexp.new(it)) }

  def max = Integer(cop_config.fetch("MaxWords", 2))

  def pattern = Regexp.new(cop_config.fetch("Pattern", "^[a-z][a-z0-9]{0,15}$"))
end
