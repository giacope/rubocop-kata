# frozen_string_literal: true

class Assay::Console
  def initialize(bundle, work, source)
    @bundle = bundle
    @work = work
    @source = source
  end

  def result
    rows = YAML.safe_load_file(@source).map { verdict(it) }
    { "total" => rows.size, "passed" => rows.count { it["passed"] }, "results" => rows }
  end

  private

  def verdict(item)
    outcome = launch(item)
    faults = faults(item.fetch("expect"), outcome)
    item.slice("id", "gap", "command").merge(
      "passed" => faults.empty?, "status" => outcome.status, "faults" => faults,
      "stdout" => outcome.stdout.lines.first(6).join, "stderr" => outcome.stderr.lines.first(3).join
    )
  end

  def launch(item)
    home = plant(item)
    executable = File.join(@bundle.kata, "exe", "rubocop-kata")
    @bundle.ruby(executable, item.fetch("command"), dir: home, env: item.fetch("env", {}))
  end

  def plant(item)
    home = File.join(@work, item.fetch("id"))
    FileUtils.rm_rf(home)
    item.fetch("files", {}).each { |path, text| write(home, path, text) }
    item.fetch("hex", {}).each { |path, text| write(home, path, [text.delete(" ")].pack("H*")) }
    home
  end

  def write(home, path, text)
    target = File.join(home, path)
    FileUtils.mkdir_p(File.dirname(target))
    File.binwrite(target, text)
  end

  def faults(expect, outcome)
    [
      *status(expect["status"], outcome.status),
      *missing(expect.fetch("stdout", []), outcome.stdout, "stdout lacks"),
      *present(expect.fetch("stdout_absent", []), outcome.stdout, "stdout has"),
      *present(expect.fetch("stderr_absent", []), outcome.stderr, "stderr has")
    ]
  end

  def status(allowed, actual)
    "exit status #{actual}, expected #{allowed}" if allowed && !allowed.include?(actual)
  end

  def missing(patterns, text, label) = patterns.reject { text.match?(Regexp.new(it)) }.map { "#{label} /#{it}/" }

  def present(patterns, text, label) = patterns.select { text.match?(Regexp.new(it)) }.map { "#{label} /#{it}/" }
end
