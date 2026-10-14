# frozen_string_literal: true

class Assay::Lexicon
  VARIANTS = {
    "shipped" => "",
    "raw" => "\nKata/GoodClassName:\n  AllowedNames: []\n  Suffixes: []\n  ContractSuffixes: []\n  Terms: []\n"
  }.freeze
  LABELS = %w[doer thing ambiguous].freeze
  DOER = "names a doer"
  SPLITS = %w[dev holdout all].freeze

  def initialize(bundle, work, source, reveal:)
    @bundle = bundle
    @work = work
    @source = source
    @reveal = reveal
  end

  def to_h
    flagged = sweep
    VARIANTS.keys.to_h { [it, splits(flagged.fetch(it, []))] }.merge("size" => names.size, "counts" => counts)
  end

  def sweep
    FileUtils.rm_rf(@work)
    VARIANTS.each { |variant, extra| plant(variant, extra) }
    report = File.join(@work, "report.json")
    @bundle.rubocop(
      "--format", "json", "--out", report, "--cache", "false", "--only", "Kata/GoodClassName",
      *VARIANTS.keys.map { File.join(it, "lib/names.rb") }, dir: @work
    )
    flags(report)
  end

  private

  def splits(flagged) = SPLITS.to_h { |split| [split, measure(split, flagged)] }

  def measure(split, flagged)
    score = Assay::Score.new(group(split), flagged)
    split == "dev" || (split == "holdout" && @reveal) ? score.to_h.merge(score.errors) : score.to_h
  end

  def group(split)
    return entries if split == "all"
    entries.select { (split == "holdout") == (Zlib.crc32(it.first) % 3).zero? }
  end

  def counts = LABELS.to_h { [it, data.fetch(it).size] }.merge("roles" => data.fetch("roles").size)

  def entries = @_entries ||= [*LABELS, "roles"].flat_map { |label| data.fetch(label).map { [it, label] } }

  def names = LABELS.flat_map { data.fetch(it) }

  def data = @_data ||= YAML.safe_load_file(@source)

  def plant(variant, extra)
    home = File.join(@work, variant, "lib")
    FileUtils.mkdir_p(home)
    File.write(File.join(@work, variant, ".rubocop.yml"), Assay::Snippets::CONFIG + extra)
    File.write(File.join(home, "names.rb"), "module Dataset\n#{names.map { "  class #{it}\n  end\n" }.join}end\n")
  end

  def flags(report)
    JSON.parse(File.read(report)).fetch("files").to_h { [it["path"].split("/").first, flagged(it)] }
  end

  def flagged(file)
    file["offenses"].select { it["message"].include?(DOER) }
      .map { names.fetch((it.dig("location", "start_line") - 2) / 2) }
  end
end
