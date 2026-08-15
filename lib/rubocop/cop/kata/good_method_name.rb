# frozen_string_literal: true

class RuboCop::Cop::Kata::GoodMethodName < RuboCop::Cop::Base
  MSG = "`%s` needs two words: either a concept is missing, or the method belongs on the object " \
    "the second word names. Say it in one word, move it, give the role a `Prefixes`/`Suffixes` " \
    "word — or, if `%s` is one domain concept here, add it to `Terms`."

  def on_def(node) = check(node, node.method_name)

  def on_defs(node) = check(node, node.method_name)

  private

  def check(node, name)
    stem = name.to_s.sub(/[?!=]\z/, "")
    return if allowed?(name.to_s) || allowed?(stem)
    return if good?(stem)
    add_offense(node.loc.name, message: format(MSG, name, name))
  end

  def good?(stem)
    words = stem.split("_")
    return false unless words.all? { pattern.match?(it) }
    core = core(words)
    return words.size == 1 if core.size == words.size
    core.size.between?(1, max)
  end

  def core(words)
    rest = prefix?(words.first) && words.size > 1 ? words.drop(1) : words
    suffix?(rest.last) && rest.size > 1 ? rest[0..-2] : rest
  end

  def prefix?(word) = list("Prefixes").include?(word)

  def suffix?(word) = list("Suffixes").include?(word)

  def allowed?(name) = list("AllowedNames").include?(name) || list("Terms").include?(name)

  def list(key) = Array(cop_config[key]).map(&:to_s)

  def max = Integer(cop_config.fetch("MaxWords", 2))

  def pattern = Regexp.new(cop_config.fetch("Pattern", "^[a-z][a-z0-9]{0,15}$"))
end
