# frozen_string_literal: true

class RuboCop::Cop::Kata::RealWords < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster

  MSG = "%s is not in the dictionary — restore the underscore between smashed words, spell the " \
    "abbreviation out, or add it to `Terms` if it is one domain term here."
  ABBREVIATION_MSG = "%s is an abbreviation; spell the word out."
  SIGIL = /\A(@@|@|\$)/
  DERIVATIONS = [
    [/s\z/, ""], [/es\z/, ""], [/ies\z/, "y"],
    [/able\z/, ""], [/able\z/, "e"], [/([b-df-hj-np-tv-z])\1able\z/, '\1'],
    [/er\z/, ""], [/[eo]r\z/, "e"], [/ier\z/, "y"],
    [/([b-df-hj-np-tv-z])\1er\z/, '\1'], [/or\z/, ""], [/less\z/, ""]
  ].freeze

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

  def on_restarg(node) = check(node, node.name)

  def on_kwrestarg(node) = check(node, node.name)

  def on_blockarg(node) = check(node, node.name)

  private

  def check(node, name)
    segment = flaw(name)
    add_offense(node.loc.name, message: format(template(segment), label(name, segment))) if segment
  end

  def flaw(name)
    stem = stem(name)
    return if allowed?(name.to_s) || allowed?(stem) || !stem.match?(/\A[a-z]/)
    stem.split("_").find { !word?(it) }
  end

  def stem(name) = name.to_s.sub(SIGIL, "").delete_prefix("_").sub(/[?!=]\z/, "")

  def template(segment) = banned?(segment) ? ABBREVIATION_MSG : MSG

  def label(name, segment) = stem(name) == segment ? "`#{name}`" : "`#{segment}` (in `#{name}`)"

  def word?(segment)
    segment.sub(/\d+\z/, "").length < 2 || listed?("Terms", segment) || (known?(segment) && !banned?(segment))
  end

  def known?(segment) = forms(segment).any? { RuboCop::Kata::Dictionary::ENTRIES.include?(it) }

  def forms(segment)
    base = segment.sub(/\d+\z/, "")
    [base, base.delete_prefix("un"), base.delete_prefix("re"), base.delete_prefix("non"), base.delete_prefix("sub")]
      .flat_map { [it, *derivations(it)] }
  end

  def derivations(base) = DERIVATIONS.map { |pattern, stem| base.sub(pattern, stem) }

  def banned?(segment) = listed?("BannedWords", segment)
end
