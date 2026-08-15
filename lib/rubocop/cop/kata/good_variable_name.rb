# frozen_string_literal: true

class RuboCop::Cop::Kata::GoodVariableName < RuboCop::Cop::Base
  MSG = "`%s` needs two words: the second word names an object you have not introduced yet. " \
    "Name that object, use a `Prefixes`/`Suffixes` role word — or, if `%s` is one domain concept " \
    "here, add it to `Terms`."

  SIGIL = /\A(@@|@|\$)/

  def on_lvasgn(node) = check(node, node.name)

  def on_ivasgn(node) = check(node, node.name)

  def on_cvasgn(node) = check(node, node.name)

  def on_gvasgn(node) = check(node, node.name)

  def on_arg(node) = check(node, node.name)

  def on_optarg(node) = check(node, node.name)

  def on_kwarg(node) = check(node, node.name)

  def on_kwoptarg(node) = check(node, node.name)

  private

  def check(node, name)
    stem = name.to_s.sub(SIGIL, "").delete_prefix("_")
    return if allowed?(name.to_s) || allowed?(stem) || stem.empty?
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
