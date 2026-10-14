# frozen_string_literal: true

class Assay::Invocation
  def initialize(bundle, home, item)
    @bundle = bundle
    @home = home
    @item = item
  end

  def to_h
    outcome = launch
    faults = faults(@item.fetch("expect"), outcome)
    @item.slice("id", "gap", "command").merge(
      "passed" => faults.empty?, "status" => outcome.status, "faults" => faults,
      "stdout" => outcome.stdout.lines.first(6).join, "stderr" => outcome.stderr.lines.first(3).join
    )
  end

  private

  def launch
    plant
    executable = File.join(@bundle.kata, "exe", "rubocop-kata")
    @bundle.ruby(executable, @item.fetch("command"), dir: @home, env: @item.fetch("env", {}))
  end

  def plant
    FileUtils.rm_rf(@home)
    @item.fetch("files", {}).each { |path, text| write(path, text) }
    @item.fetch("hex", {}).each { |path, text| write(path, [text.delete(" ")].pack("H*")) }
  end

  def write(path, text)
    target = File.join(@home, path)
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
