# frozen_string_literal: true

require "optparse"

class Assay::Session
  SECTIONS = %w[settings cases names cli corpora].freeze
  KEPT = %w[
    PATH HOME GEM_HOME GEM_PATH BUNDLE_PATH LANG LC_ALL TMPDIR SSL_CERT_FILE HTTPS_PROXY HTTP_PROXY NO_PROXY
  ].freeze
  USAGE = "usage: eval/run --kata PATH [--out FILE] [--only LIST] [--list CORPORA] [--labels FILE] [--gate] | " \
    "eval/run --compare BEFORE AFTER [--out FILE] | eval/run --draw [--out FILE]"
  DEFAULTS = { only: SECTIONS, jobs: 4, elegant: "0.8.0" }.freeze
  FLAGS = [
    ["--only LIST", Array], ["--jobs N", Integer], ["--elegant VERSION", String],
    ["--reveal"], ["--compare"], ["--gate"], ["--draw"]
  ].freeze
  ROOT = File.expand_path("../..", __dir__)
  NAMES = File.join(ROOT, "names.yml")
  CORPORA = File.join(ROOT, "corpora.yml")
  SHEET = File.join(ROOT, "results", "human", "names.yml")
  PATHS = %w[kata out work corpora list labels].freeze
  BUILDERS = {
    "settings" => ->(bundle, home, _) { Assay::Settings.new(bundle, home) },
    "cases" => ->(bundle, home, _) { Assay::Snippets.new(bundle, home, Dir[File.join(ROOT, "cases", "*.yml")]) },
    "names" => ->(bundle, home, options) { Assay::Lexicon.new(bundle, home, NAMES, reveal: options[:reveal]) },
    "cli" => ->(bundle, home, options) { Assay::Console.new(bundle, home, File.join(ROOT, "cli.yml"), options[:kata]) },
    "human" => ->(bundle, home, options) { Assay::Agreement.new(bundle, home, options[:labels] || SHEET) }
  }.freeze

  def initialize(arguments, io:, env:, scratch: Dir.tmpdir)
    @arguments = arguments
    @io = io
    @env = env
    @scratch = scratch
  end

  def run
    return compare if options[:compare]
    return emit(Assay::Sample.new(NAMES).to_s) if options[:draw]
    options[:kata] ? assay : @io.puts(USAGE)
  end

  def status
    return 0 if options[:compare] || options[:draw]
    return 1 unless options[:kata]
    options[:gate] ? Assay::Gate.new(score).status : 0
  end

  private

  def assay
    write(score)
    Assay::Gate.new(score).check(@io) if options[:gate]
  end

  def options = @_options ||= DEFAULTS.merge(parsed)

  def parsed = {}.tap { parser.parse(@arguments, into: it) }

  def parser
    OptionParser.new do |parser|
      PATHS.each { |key| parser.on("--#{key} PATH", String) { |value| File.expand_path(value) } }
      FLAGS.each { parser.on(*it) }
    end
  end

  def compare
    before, after = parser.parse(@arguments).map { JSON.parse(File.read(it)) }
    emit(Assay::Comparison.new(before, after).markdown)
  end

  def emit(text) = options[:out] ? File.write(options[:out], text) : @io.puts(text)

  def score = @_score ||= scored

  def scored
    bundle = Assay::Bundle.new(options[:kata], work, shell, elegant: options[:elegant]).prepare
    options[:only].each_with_object({ "kata" => bundle.to_h }) do |name, data|
      @io.puts("assay: #{name}")
      data[name] = section(name, bundle)
    end
  end

  def work = options[:work] || File.join(@scratch, "assay", File.basename(options[:kata]))

  def section(name, bundle)
    return corpora(bundle) if name == "corpora"
    BUILDERS.fetch(name).call(bundle, File.join(work, name), options).to_h
  end

  def corpora(bundle)
    Assay::Fleet.new(specs, options[:jobs]).results do |spec|
      Assay::Corpus.new(spec, bundle, work, shell).to_h.tap { @io.puts("assay: corpus #{spec["name"]} done") }
    end
  end

  def specs = @_specs ||= YAML.safe_load_file(options[:list] || CORPORA).map { it.merge("cache" => cache) }

  def cache = options[:corpora] || File.join(ROOT, "..", "tmp", "eval", "corpora")

  def shell = Assay::Shell.new(@env.slice(*KEPT))

  def write(data)
    out = options[:out] || File.join(ROOT, "results", "latest.json")
    FileUtils.mkdir_p(File.dirname(out))
    File.write(out, "#{JSON.pretty_generate(data)}\n")
    File.write(out.sub(/\.json\z/, ".md"), Assay::Comparison.new(nil, data).markdown)
    @io.puts("assay: wrote #{out}")
  end
end
