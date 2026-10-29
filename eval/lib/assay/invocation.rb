# frozen_string_literal: true

class Assay::Invocation
  def initialize(bundle, work, item, kata)
    @bundle = bundle
    @work = work
    @item = item
    @kata = kata
  end

  def to_h
    stdout, stderr, status = launch
    faults = faults(@item.fetch("expect"), stdout, stderr, status)
    @item.slice("id", "gap", "command", "known").merge(
      "passed" => faults.empty?, "status" => status, "faults" => faults,
      "stdout" => stdout.lines.first(6).join, "stderr" => stderr.lines.first(3).join
    )
  end

  private

  def home = File.join(@work, @item.fetch("id"))

  def launch
    plant
    executable = File.join(@kata, "exe", "rubocop-kata")
    @bundle.ruby(executable, @item.fetch("command"), dir: home, env: @item.fetch("env", {}))
  end

  def plant
    FileUtils.rm_rf(home)
    @item.fetch("files", {}).each { |path, text| write(path, text) }
    @item.fetch("hex", {}).each { |path, text| write(path, [text.delete(" ")].pack("H*")) }
  end

  def write(path, text)
    target = File.join(home, path)
    FileUtils.mkdir_p(File.dirname(target))
    File.binwrite(target, text)
  end

  def faults(expect, stdout, stderr, status)
    [
      *exited(expect["status"], status),
      *missing(expect.fetch("stdout", []), stdout, "stdout lacks"),
      *present(expect.fetch("stdout_absent", []), stdout, "stdout has"),
      *present(expect.fetch("stderr_absent", []), stderr, "stderr has")
    ]
  end

  def exited(allowed, actual)
    allowed && !allowed.include?(actual) ? ["exit status #{actual}, expected #{allowed}"] : []
  end

  def missing(patterns, text, label) = patterns.reject { text.match?(Regexp.new(it)) }.map { "#{label} /#{it}/" }

  def present(patterns, text, label) = patterns.select { text.match?(Regexp.new(it)) }.map { "#{label} /#{it}/" }
end
