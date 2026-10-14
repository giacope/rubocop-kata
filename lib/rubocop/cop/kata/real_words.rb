# frozen_string_literal: true

class RuboCop::Cop::Kata::RealWords < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster
  include RuboCop::Cop::Kata::Minting

  MSG = "%s is not in the dictionary — restore the underscore between smashed words, spell the " \
    "abbreviation out, or add it to `Terms` if it is one domain term here."
  ABBREVIATION_MSG = "%s is an abbreviation; spell the word out."
  CLIPPING_MSG = "%s is an abbreviation of `%s`; spell the word out."
  PLACEHOLDER_MSG = "%s is a placeholder; name what it holds."
  PLACEHOLDER = "placeholder"
  RESTRICT_ON_SEND = RuboCop::Cop::Kata::Minting::MINTERS
  SIGIL = /\A(@@|@|\$)/
  DERIVATIONS = [
    [/s\z/, ""], [/es\z/, ""], [/ies\z/, "y"],
    [/able\z/, ""], [/able\z/, "e"], [/([b-df-hj-np-tv-z])\1able\z/, '\1'],
    [/er\z/, ""], [/[eo]r\z/, "e"], [/ier\z/, "y"],
    [/([b-df-hj-np-tv-z])\1er\z/, '\1'], [/or\z/, ""], [/less\z/, ""]
  ].freeze

  PREFIXES = %w[un re non sub].freeze
  NAMED = %i[ivasgn cvasgn gvasgn arg optarg kwarg kwoptarg restarg kwrestarg blockarg].freeze

  def on_def(node) = mint(node.loc.name, node.method_name)

  alias on_defs on_def

  def on_lvasgn(node) = mint(node.loc.name, node.name)

  NAMED.each { alias_method(:"on_#{it}", :on_lvasgn) }

  private

  def mint(range, name)
    stem = name.to_s.sub(SIGIL, "").delete_prefix("_").sub(/[?!=]\z/, "")
    return if allowed?(name.to_s) || allowed?(stem) || !stem.match?(/\A[a-z]/)
    segment = stem.split("_").find { !word?(it) }
    add_offense(range, message: message(name, stem, segment)) if segment
  end

  def message(name, stem, segment)
    label = stem == segment ? "`#{name}`" : "`#{segment}` (in `#{name}`)"
    return format(MSG, label) unless banned?(segment)
    expansion = bases(segment).filter_map { RuboCop::Kata::Dictionary::CLIPPINGS[it] }.first
    return format(PLACEHOLDER_MSG, label) if expansion == PLACEHOLDER
    expansion ? format(CLIPPING_MSG, label, expansion) : format(ABBREVIATION_MSG, label)
  end

  def word?(segment)
    base = segment.sub(/\d+\z/, "")
    return true if base.length < 2 || listed?("Terms", segment)
    [base, *PREFIXES.map { base.delete_prefix(it) }]
      .flat_map { |form| [form, *DERIVATIONS.map { |pattern, stem| form.sub(pattern, stem) }] }
      .any? { RuboCop::Kata::Dictionary::ENTRIES.include?(it) } && !banned?(segment)
  end

  def banned?(segment) = bases(segment).any? { listed?("BannedWords", it) || clipping?(it) }

  def clipping?(segment) = RuboCop::Kata::Dictionary::CLIPPINGS.key?(segment)

  def bases(segment)
    plain = segment.sub(/\d+\z/, "")
    return [plain] if RuboCop::Kata::Dictionary::ENTRIES.include?(plain) && !clipping?(plain)
    [plain, plain.sub(/e?s\z/, ""), plain.delete_suffix("s")].uniq
  end
end
