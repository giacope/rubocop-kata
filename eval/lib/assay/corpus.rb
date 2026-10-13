# frozen_string_literal: true

class Assay::Corpus
  BARE = Assay::Snippets::CONFIG
  LENGTHS = {
    "kata" => nil,
    "without_method_call" => %w[array hash heredoc],
    "raw" => []
  }.freeze
  FAILURE = /error occurred|infinite loop/i

  def initialize(spec, bundle, cache:, work:, shell:)
    @spec = spec
    @bundle = bundle
    @cache = cache
    @work = work
    @shell = shell
  end

  def result
    check = export("check")
    report = sweep(check)
    base = summary(report, check).merge("sha" => @spec.fetch("sha"), "config" => @spec.fetch("config"))
    base["method_length"] = lengths(check)
    base["pristine_test"] = test(check) if @spec["test"]
    base["offense_list"] = listing(report) if @spec.fetch("config") == "own"
    base.merge(fixes)
  end

  private

  def fixes = @spec["fix"] ? { "safe" => fix("safe", "-a"), "all" => fix("all", "-A") } : {}

  def fix(label, flag)
    dir = export(label)
    before = Assay::Census.new(dir, paths).tally
    outcome = @bundle.rubocop(flag, "--format", "json", "--out", "fix.json", "--cache", "false", *paths, dir: dir)
    census = Assay::Census.new(dir, paths)
    {
      "corrected" => corrected(File.join(dir, "fix.json")), "comments_before" => before,
      "comments_after" => census.tally, "unparsable" => census.broken, "failures" => failures(outcome),
      "test" => (test(dir) if @spec["test"])
    }.compact
  end

  def corrected(path)
    return 0 unless File.file?(path)
    JSON.parse(File.read(path)).fetch("files").sum { |file| file["offenses"].count { it["corrected"] } }
  end

  def failures(outcome) = outcome.stderr.lines.grep(FAILURE).map(&:strip).uniq.first(20)

  def test(dir)
    command = @spec.fetch("test").gsub("{shims}", File.join(Assay::ROOT, "support", "shims"))
    outcome = @shell.run("sh", "-c", command, dir: dir)
    examples, failed = outcome.stdout.scan(/(\d+) examples?, (\d+) failures?/).last&.map(&:to_i)
    { "status" => outcome.status, "examples" => examples, "failures" => failed }
  end

  def sweep(dir)
    @bundle.rubocop("--format", "json", "--out", "report.json", "--cache", "false", *paths, dir: dir)
    JSON.parse(File.read(File.join(dir, "report.json")))
  end

  def summary(report, dir)
    files = report.fetch("files")
    lines = files.sum { File.foreach(File.join(dir, it["path"])).count }
    counts = files.flat_map { |file| file["offenses"].map { it["cop_name"] } }.tally.sort_by { -it.last }.to_h
    {
      "files" => files.size, "lines" => lines, "offenses" => counts.values.sum, "counts" => counts,
      "per_kloc" => counts.transform_values { (it * 1000.0 / lines).round(2) }
    }
  end

  def listing(report)
    report.fetch("files").flat_map do |file|
      file["offenses"].map { [file["path"], it.dig("location", "start_line"), it["cop_name"], it["message"]] }
    end
  end

  def lengths(dir)
    LENGTHS.to_h do |label, folded|
      [label, length(dir, label, folded)]
    end
  end

  def length(dir, label, folded)
    arguments = ["--only", "Metrics/MethodLength", "--format", "json", "--out", "length-#{label}.json", "--cache", "false"]
    arguments += ["-c", variant(dir, label, folded)] if folded
    @bundle.rubocop(*arguments, *paths, dir: dir)
    JSON.parse(File.read(File.join(dir, "length-#{label}.json"))).dig("summary", "offense_count")
  end

  def variant(dir, label, folded)
    path = File.join(dir, ".rubocop-length-#{label}.yml")
    File.write(path, "inherit_from: .rubocop.yml\n\nMetrics/MethodLength:\n  CountAsOne: #{folded.to_json}\n")
    path
  end

  def export(label)
    dir = File.join(@work, label)
    FileUtils.rm_rf(dir)
    FileUtils.mkdir_p(dir)
    archive = "git -C #{source} archive --format=tar #{@spec.fetch("sha")} | tar -x -C #{dir}"
    outcome = @shell.run("sh", "-c", archive, dir: dir)
    raise "export of #{name} failed: #{outcome.stderr}" unless outcome.status.zero?
    File.write(File.join(dir, ".rubocop.yml"), BARE) if @spec.fetch("config") == "bare"
    dir
  end

  def source
    path = File.join(@cache, name)
    return path if File.directory?(path)
    FileUtils.mkdir_p(@cache)
    @shell.run("git", "clone", "--quiet", "--no-checkout", @spec.fetch("url"), path, dir: @cache)
    path
  end

  def name = @spec.fetch("name")

  def paths = @spec.fetch("paths")
end
