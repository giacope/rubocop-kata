# frozen_string_literal: true

class Assay::Lexicon
  VARIANTS = {
    "shipped" => "",
    "raw" => "\nKata/GoodClassName:\n  AllowedNames: []\n  Suffixes: []\n  Terms: []\n"
  }.freeze
  LABELS = %w[doer thing ambiguous].freeze
  DOER = "names a doer"

  def initialize(bundle, work, source, reveal:)
    @bundle = bundle
    @work = work
    @source = source
    @reveal = reveal
  end

  def result
    flagged = sweep
    VARIANTS.keys.to_h { [it, score(flagged.fetch(it, []))] }.merge("size" => names.size, "counts" => counts)
  end

  private

  def score(flagged)
    splits = { "dev" => entries.reject { held?(it) }, "holdout" => entries.select { held?(it) }, "all" => entries }
    splits.to_h { |split, group| [split, metrics(group, flagged, split)] }
  end

  def metrics(group, flagged, split)
    hits = group.select { flagged.include?(it.first) }
    tally = counts.keys.to_h { |label| [label, hits.count { it.last == label }] }
    total = group.map(&:last).tally
    summary(tally, total).merge(errors(group, flagged, split))
  end

  def summary(tally, total)
    caught = tally.fetch("doer")
    wrong = tally.fetch("thing")
    missed = total.fetch("doer", 0) - caught
    precision = ratio(caught, caught + wrong)
    recall = ratio(caught, caught + missed)
    {
      "tp" => caught, "fp" => wrong, "fn" => missed, "precision" => precision, "recall" => recall,
      "f1" => ratio(2 * precision * recall, precision + recall),
      "ambiguous_flagged" => tally.fetch("ambiguous"), "ambiguous" => total.fetch("ambiguous", 0),
      "roles_flagged" => tally.fetch("roles"), "roles" => total.fetch("roles", 0)
    }
  end

  def errors(group, flagged, split)
    return {} if split == "all" || (split == "holdout" && !@reveal)
    {
      "false_positives" => group.select { it.last == "thing" && flagged.include?(it.first) }.map(&:first),
      "false_negatives" => group.select { it.last == "doer" && !flagged.include?(it.first) }.map(&:first)
    }
  end

  def ratio(part, whole) = whole.zero? ? 0.0 : (part.to_f / whole).round(4)

  def held?(entry) = (Zlib.crc32(entry.first) % 3).zero?

  def counts = @_counts ||= LABELS.to_h { [it, data.fetch(it).size] }.merge("roles" => data.fetch("roles").size)

  def entries
    @_entries ||= LABELS.flat_map { |label| data.fetch(label).map { [it, label] } } +
      data.fetch("roles").map { [it, "roles"] }
  end

  def names = LABELS.flat_map { data.fetch(it) }

  def data = @_data ||= YAML.safe_load_file(@source)

  def sweep
    FileUtils.rm_rf(@work)
    VARIANTS.each { |variant, extra| plant(variant, extra) }
    report = File.join(@work, "report.json")
    files = VARIANTS.keys.map { File.join(it, "lib/names.rb") }
    @bundle.rubocop("--format", "json", "--out", report, "--cache", "false", "--only", "Kata/GoodClassName", *files,
      dir: @work)
    flags(report)
  end

  def plant(variant, extra)
    home = File.join(@work, variant, "lib")
    FileUtils.mkdir_p(home)
    File.write(File.join(@work, variant, ".rubocop.yml"), Assay::Snippets::CONFIG + extra)
    File.write(File.join(home, "names.rb"), "module Dataset\n#{names.map { "  class #{it}\n  end\n" }.join}end\n")
  end

  def flags(report)
    JSON.parse(File.read(report)).fetch("files").to_h do |file|
      lines = file["offenses"].select { it["message"].include?(DOER) }.map { it.dig("location", "start_line") }
      [file["path"].split("/").first, lines.map { names.fetch((it - 2) / 2) }]
    end
  end
end
