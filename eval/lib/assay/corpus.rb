# frozen_string_literal: true

class Assay::Corpus
  LENGTHS = { "kata" => nil, "without_method_call" => %w[array hash heredoc], "raw" => [] }.freeze
  SHIMS = File.join(Assay::ROOT, "support", "shims")

  attr_reader :bundle

  def initialize(spec, bundle, work, shell)
    @spec = spec
    @bundle = bundle
    @work = work
    @shell = shell
  end

  def to_h
    check = export("check")
    report = sweep(check)
    summary(report, check).merge(@spec.slice("sha", "config"), "method_length" => lengths(check))
      .merge("pristine_test" => test(check), "offense_list" => listing(report), **fixes).compact
  end

  def paths = @spec.fetch("paths")

  def test(dir)
    return unless @spec["test"]
    outcome = @shell.run("sh", "-c", @spec.fetch("test").gsub("{shims}", SHIMS), dir: dir)
    examples, failed = outcome.stdout.scan(/(\d+) examples?, (\d+) failures?/).last&.map(&:to_i)
    { "status" => outcome.status, "examples" => examples, "failures" => failed }
  end

  private

  def fixes
    return {} unless @spec["fix"]
    { "safe" => Assay::Repair.new(self, export("safe"), "-a").to_h, "all" => Assay::Repair.new(self, export("all"), "-A").to_h }
  end

  def sweep(dir)
    @bundle.rubocop("--format", "json", "--out", "report.json", "--cache", "false", *paths, dir: dir)
    JSON.parse(File.read(File.join(dir, "report.json")))
  end

  def summary(report, dir)
    files = report.fetch("files")
    lines = files.sum { File.foreach(File.join(dir, it["path"])).count }
    counts = files.flat_map { |file| file["offenses"].map { it["cop_name"] } }.tally.sort_by { -it.last }.to_h
    Assay::Density.new(files.size, lines, counts).to_h
  end

  def listing(report)
    return unless @spec.fetch("config") == "own"
    report.fetch("files").flat_map do |file|
      file["offenses"].map { [file["path"], it.dig("location", "start_line"), it["cop_name"], it["message"]] }
    end
  end

  def lengths(dir) = LENGTHS.to_h { |label, folded| [label, length(dir, label, folded)] }

  def length(dir, label, folded)
    out = "length-#{label}.json"
    option = folded ? ["-c", variant(dir, label, folded)] : []
    @bundle.rubocop(
      "--only", "Metrics/MethodLength", "--format", "json", "--out", out, "--cache", "false", *option, *paths, dir: dir
    )
    JSON.parse(File.read(File.join(dir, out))).dig("summary", "offense_count")
  end

  def variant(dir, label, folded)
    path = File.join(dir, ".rubocop-length-#{label}.yml")
    File.write(path, "inherit_from: .rubocop.yml\n\nMetrics/MethodLength:\n  CountAsOne: #{folded.to_json}\n")
    path
  end

  def export(label)
    dir = File.join(@work, label)
    unpack(dir)
    File.write(File.join(dir, ".rubocop.yml"), Assay::Snippets::CONFIG) if @spec.fetch("config") == "bare"
    dir
  end

  def unpack(dir)
    FileUtils.rm_rf(dir)
    FileUtils.mkdir_p(dir)
    archive = "git -C #{source} archive --format=tar #{@spec.fetch("sha")} | tar -x -C #{dir}"
    outcome = @shell.run("sh", "-c", archive, dir: dir)
    raise(Assay::Failure, "export of #{name} failed: #{outcome.stderr}") unless outcome.status.zero?
  end

  def source
    path = File.join(cache, name)
    clone(path) unless File.directory?(path)
    path
  end

  def clone(path)
    FileUtils.mkdir_p(@work)
    @shell.run("git", "clone", "--quiet", "--no-checkout", @spec.fetch("url"), path, dir: @work)
  end

  def cache = @spec.fetch("cache")

  def name = @spec.fetch("name")
end
