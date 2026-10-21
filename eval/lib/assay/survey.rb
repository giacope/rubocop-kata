# frozen_string_literal: true

class Assay::Survey
  include Assay::Reporting

  MODES = { "safe" => "-a", "all" => "-A" }.freeze
  FOLDS = %w[kata without_method_call raw].freeze
  SAFETY = ["Corpus", "Mode", "Unparsable", "Comments kept", "YARD kept", "Encoding kept", "Test failures"].freeze
  KINDS = [nil, "yard", "encoding"].freeze
  ALLOWLIST = File.join(Assay::ROOT, "..", "data", "autocorrect.txt")

  def to_a = [corpora, safety, allowlist, lengths, *movement, *drift]

  private

  def names = @after.fetch("corpora").keys

  def corpora
    section("Corpora", %w[Corpus Offenses PerKLOC], names.map { [it, shift("corpora", it, "offenses"), rate(it)] })
  end

  def rate(name)
    [@before, @after].filter_map { it.dig("corpora", name) }.map { (it["offenses"] * 1000.0 / it["lines"]).round(1) }
      .uniq.join(" → ")
  end

  def safety = section("Autocorrect safety", SAFETY, names.flat_map { |name| MODES.keys.filter_map { fix(name, it) } })

  def fix(name, mode)
    rows = [@before, @after].filter_map { it.dig("corpora", name, mode) }
    return if rows.empty?
    [name, MODES.fetch(mode), *cells.map { |cell| rows.map { cell.call(it) }.join(" → ") }]
  end

  def cells
    [
      ->(row) { row["unparsable"].size }, *KINDS.map { |kind| ->(row) { share(row, kind) } },
      ->(row) { row["test"] ? row.dig("test", "failures").inspect : "n/a" }
    ]
  end

  def share(row, kind)
    path = kind ? ["kinds", kind] : ["comments"]
    "#{row["comments_after"].dig(*path).to_i}/#{row["comments_before"].dig(*path).to_i}"
  end

  def allowlist
    proven = names.flat_map { proven(it) }
    idle = File.readlines(ALLOWLIST, chomp: true) - proven
    section("Allowlisted corrections no green suite ran this time", %w[Cop], idle.zip)
  end

  def proven(name)
    run = @after.dig("corpora", name, "safe") || {}
    failures = run.dig("test", "failures")
    return [] unless failures && failures <= @after.dig("corpora", name, "pristine_test", "failures").to_i
    run.fetch("corrected_cops", [])
  end

  def lengths
    section(
      "Metrics/MethodLength offenses by CountAsOne", %w[Corpus kata without_method_call none],
      names.map { |name| [name, *FOLDS.map { shift("corpora", name, "method_length", it) }] }
    )
  end

  def movement
    names.map do |name|
      section("#{name}: offenses per kLOC by cop", %w[Cop Before After Delta], cops(name).map { density(name, it) })
    end
  end

  def cops(name)
    [@before, @after].flat_map { (it.dig("corpora", name, "counts") || {}).keys }.uniq
      .select { relevant?(name, it) }.sort
  end

  def density(name, cop) = [cop, *[@before, @after].map { per(it, name, cop) }, delta(name, cop)]

  def relevant?(name, cop)
    cop.start_with?("Kata/") || [@before, @after].any? { per(it, name, cop) >= 1.0 } || delta(name, cop).abs >= 0.5
  end

  def per(data, name, cop) = data.dig("corpora", name, "per_kloc", cop) || 0.0

  def delta(name, cop) = (per(@after, name, cop) - per(@before, name, cop)).round(2)

  def drift
    names.filter_map do |name|
      now = @after.dig("corpora", name, "offense_list")
      old = @before.dig("corpora", name, "offense_list")
      section("#{name}: offenses this change adds and removes", %w[Cop Added Removed], tally(now, old)) if now && old
    end
  end

  def tally(now, old)
    added = keys(now, old).tally
    removed = keys(old, now).tally
    (added.keys | removed.keys).sort.map { [it, added.fetch(it, 0), removed.fetch(it, 0)] }
  end

  def keys(left, right) = (left.map { it.first(3) } - right.map { it.first(3) }).map(&:last)
end
