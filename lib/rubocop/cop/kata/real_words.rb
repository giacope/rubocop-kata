# frozen_string_literal: true

require "zlib"

class RuboCop::Cop::Kata::RealWords < RuboCop::Cop::Base
  MSG = "%s is not in the dictionary — restore the underscore between smashed words, spell the " \
    "abbreviation out, or add it to `Terms` if it is one domain term here."
  ABBREVIATION_MSG = "%s is an abbreviation; spell the word out."
  WORDS = File.expand_path("../../../../data/words.txt.gz", __dir__)
  SOFTWARE = File.expand_path("../../../../data/software.txt.gz", __dir__)
  EXTRA = File.expand_path("../../../../data/supplement.txt", __dir__)
  DICTIONARY = Set.new(
    [WORDS, SOFTWARE].flat_map { Zlib.gunzip(File.binread(it)).split("\n") } +
      File.readlines(EXTRA, chomp: true)
  ).freeze
  SIGIL = /\A(@@|@|\$)/

  def on_def(node) = check(node, node.method_name)

  def on_defs(node) = check(node, node.method_name)

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
    stem = name.to_s.sub(SIGIL, "").delete_prefix("_").sub(/[?!=]\z/, "")
    segment = flaw(name.to_s, stem)
    return unless segment
    add_offense(node.loc.name, message: message(name, stem, segment))
  end

  def flaw(name, stem)
    return if allowed?(name) || allowed?(stem) || !stem.match?(/\A[a-z]/)
    stem.split("_").find { !word?(it) }
  end

  def message(name, stem, segment)
    format(banned?(segment) ? ABBREVIATION_MSG : MSG, label(name, stem, segment))
  end

  def label(name, stem, segment) = stem == segment ? "`#{name}`" : "`#{segment}` (in `#{name}`)"

  def word?(segment) = segment.length < 2 || term?(segment) || (known?(segment) && !banned?(segment))

  def known?(segment) = forms(segment).any? { DICTIONARY.include?(it) }

  def forms(segment)
    base = segment.sub(/\d+\z/, "")
    roots = [base, base.delete_prefix("un"), base.delete_prefix("re"), base.delete_prefix("non"), base.delete_prefix("sub")]
    # Productive derivations (groupable, approver, imageless) are formed by
    # affix rule in spellcheckers, so SCOWL does not list them.
    roots.flat_map { [it, *derivations(it)] }
  end

  def derivations(base)
    [
      base.delete_suffix("s"), base.delete_suffix("es"), base.sub(/ies\z/, "y"),
      base.delete_suffix("able"), base.sub(/able\z/, "e"), base.sub(/([b-df-hj-np-tv-z])\1able\z/, '\1'),
      base.delete_suffix("er"), base.sub(/[eo]r\z/, "e"), base.sub(/ier\z/, "y"),
      base.sub(/([b-df-hj-np-tv-z])\1er\z/, '\1'), base.delete_suffix("or"), base.delete_suffix("less")
    ]
  end

  def term?(segment) = list("Terms").include?(segment)

  def banned?(segment) = list("BannedWords").include?(segment)

  def allowed?(name) = list("AllowedNames").include?(name)

  def list(key) = Array(cop_config[key]).map(&:to_s)
end
