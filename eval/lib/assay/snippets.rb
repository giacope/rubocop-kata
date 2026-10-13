# frozen_string_literal: true

class Assay::Snippets
  CONFIG = "plugins:\n  - rubocop-kata\n\nAllCops:\n  TargetRubyVersion: 3.4\n  SuggestExtensions: false\n"
  PATH = "lib/sample.rb"
  MODES = { "safe" => "-a", "all" => "-A" }.freeze
  EXTRA = 99

  def initialize(bundle, work, sources)
    @bundle = bundle
    @work = work
    @sources = sources
  end

  def to_h
    rows = verdicts
    { "total" => rows.size, "passed" => rows.count { it["passed"] }, "by_gap" => gaps(rows), "results" => rows }
  end

  private

  def verdicts
    found = sweep("detect", cases, [])
    fixed = corrections
    cases.map { Assay::Verdict.new(it, found.fetch(it["id"], []), fixed[it["id"]]).to_h }
  end

  def corrections
    cases.select { it["correct"] }.group_by { [it["correct"], it["only"] ? it["cop"] : nil] }
      .each_with_index.flat_map { |(key, group), index| repair(key, group, index) }.to_h
  end

  def repair(key, group, index)
    mode, cop = key
    label = "#{mode}-#{index}"
    sweep(label, group, [MODES.fetch(mode), *(["--only", cop] if cop)])
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
    @bundle.rubocop(
      "--format", "json", "--out", report(label), "--cache", "false", "--force-exclusion", *extra,
      *group.map { File.join(it["id"], it.fetch("path", PATH)) }, dir: root
    )
    offenses(report(label))
  end

  def report(label) = File.join(@work, "#{label}.json")

  def plant(root, item)
    home = File.join(root, item["id"])
    path = File.join(home, item.fetch("path", PATH))
    FileUtils.mkdir_p(File.dirname(path))
    File.write(File.join(home, ".rubocop.yml"), CONFIG)
    File.write(path, item.fetch("source"))
  end

  def offenses(path)
    JSON.parse(File.read(path)).fetch("files").group_by { it["path"].split("/").first }
      .transform_values { |files| files.flat_map { it["offenses"] } }
  end

  def gaps(rows)
    rows.group_by { it["gap"] }.sort_by { |gap, _| gap.delete("R").to_i.nonzero? || EXTRA }.to_h
      .transform_values { |group| { "total" => group.size, "passed" => group.count { it["passed"] } } }
  end

  def cases = @_cases ||= @sources.flat_map { |path| load(path) }

  def load(path)
    gap = File.basename(path)[/\Ar(\d+)/, 1].to_i
    label = gap == EXTRA ? "extra" : "R#{gap}"
    YAML.safe_load_file(path).flat_map { expand(it.merge("gap" => label)) }
  end

  def expand(item)
    words = item.delete("each")
    return [item] unless words
    words.map { |word| item.merge("id" => "#{item["id"]}-#{word}", "source" => item["source"].gsub("{word}", word)) }
  end
end
