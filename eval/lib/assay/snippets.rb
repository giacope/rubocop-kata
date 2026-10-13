# frozen_string_literal: true

class Assay::Snippets
  CONFIG = "plugins:\n  - rubocop-kata\n\nAllCops:\n  TargetRubyVersion: 3.4\n  SuggestExtensions: false\n"
  PATH = "lib/sample.rb"
  MODES = { "safe" => "-a", "all" => "-A" }.freeze

  def initialize(bundle, work, sources)
    @bundle = bundle
    @work = work
    @sources = sources
  end

  def result
    rows = verdicts
    { "total" => rows.size, "passed" => rows.count { it["passed"] }, "by_gap" => gaps(rows), "results" => rows }
  end

  private

  def verdicts
    found = sweep("detect", cases, [])
    fixed = corrections
    cases.map { verdict(it, found.fetch(it["id"], []), fixed[it["id"]]) }
  end

  def verdict(item, offenses, text)
    mine = offenses.select { it["cop_name"] == item["cop"] }
    faults = [expectation(item, mine), *survival(item, text)].compact
    item.slice("id", "gap", "cop", "expect").merge(
      "passed" => faults.empty?, "found" => mine.size, "faults" => faults,
      "messages" => mine.map { it["message"] }.uniq.first(2)
    )
  end

  def expectation(item, mine)
    case item["expect"]
    when "offense" then "expected an offense, found none" if mine.empty?
    when "clean" then "expected no offense, found #{mine.size}" unless mine.empty?
    end
  end

  def survival(item, text)
    return [] unless item["correct"]
    return ["the corrected file is missing"] if text.nil?
    lines = text.lines.map(&:chomp)
    lost = item.fetch("keeps", []).reject { lines.include?(it) }.map { "correction removed #{it.inspect}" }
    lost + Array(shape(item, text))
  end

  def shape(item, text)
    expected = item["becomes"]
    "correction produced #{text.inspect}" if expected && expected != text
  end

  def corrections
    cases.select { it["correct"] }.group_by { [it["correct"], it["only"] ? it["cop"] : nil] }
      .each_with_index.flat_map { |((mode, cop), group), index| repair(mode, cop, group, index) }.to_h
  end

  def repair(mode, cop, group, index)
    label = "#{mode}-#{index}"
    extra = [MODES.fetch(mode), *(["--only", cop] if cop)]
    sweep(label, group, extra)
    group.map { [it["id"], read(label, it)] }
  end

  def read(label, item)
    path = File.join(@work, label, item["id"], item.fetch("path", PATH))
    File.file?(path) ? File.read(path) : nil
  end

  def sweep(label, group, extra)
    root = File.join(@work, label)
    FileUtils.rm_rf(root)
    group.each { plant(root, it) }
    report = File.join(@work, "#{label}.json")
    files = group.map { File.join(it["id"], it.fetch("path", PATH)) }
    @bundle.rubocop("--format", "json", "--out", report, "--cache", "false", "--force-exclusion", *extra, *files, dir: root)
    offenses(report)
  end

  def plant(root, item)
    home = File.join(root, item["id"])
    path = File.join(home, item.fetch("path", PATH))
    FileUtils.mkdir_p(File.dirname(path))
    File.write(File.join(home, ".rubocop.yml"), CONFIG)
    File.write(path, item.fetch("source"))
  end

  def offenses(report)
    JSON.parse(File.read(report)).fetch("files").group_by { it["path"].split("/").first }
      .transform_values { |files| files.flat_map { it["offenses"] } }
  end

  def gaps(rows)
    rows.group_by { it["gap"] }.sort_by { |gap, _| gap.delete("R").to_i.nonzero? || 99 }.to_h.transform_values do |group|
      { "total" => group.size, "passed" => group.count { it["passed"] } }
    end
  end

  def cases = @_cases ||= @sources.flat_map { |path| load(path) }

  def load(path)
    gap = File.basename(path)[/\Ar(\d+)/, 1].to_i
    label = gap == 99 ? "extra" : format("R%d", gap)
    YAML.safe_load_file(path).flat_map { expand(it.merge("gap" => label)) }
  end

  def expand(item)
    words = item.delete("each")
    return [item] unless words
    words.map do |word|
      item.merge("id" => "#{item["id"]}-#{word}", "source" => item["source"].gsub("{word}", word))
    end
  end
end
