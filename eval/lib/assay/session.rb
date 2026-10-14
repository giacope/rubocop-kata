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
  NAMES = File.join(Assay::ROOT, "names.yml")
  CORPORA = File.join(Assay::ROOT, "corpora.yml")
  SHEET = File.join(Assay::ROOT, "results", "human", "names.yml")
  PATHS = %w[kata out work corpora list labels].freeze
  BUILDERS = {
    "settings" => ->(bundle, home, _) { Assay::Settings.new(bundle, home) },
    "cases" => ->(bundle, home, _) { Assay::Snippets.new(bundle, home, Dir[File.join(Assay::ROOT, "cases", "*.yml")]) },
    "names" => ->(bundle, home, options) { Assay::Lexicon.new(bundle, home, NAMES, reveal: options[:reveal]) },
    "cli" => ->(bundle, home, _) { Assay::Console.new(bundle, home, File.join(Assay::ROOT, "cli.yml")) },
    "human" => ->(bundle, home, options) { Assay::Agreement.new(bundle, home, options[:labels] || SHEET) }
  }.freeze

  def initialize(arguments, io:, env:)
    @arguments = arguments
    @io = io
    @env = env
  end

  def run
    return compare if options[:compare]
    return emit(Assay::Sample.new(NAMES).to_s) if options[:draw]
    return usage unless options[:kata]
    gate(score.tap { write(it) })
  end

  private

  def usage
    @io.puts(USAGE)
    1
  end

  def options = @_options ||= DEFAULTS.merge(parsed)

  def parsed
    found = {}
    parser.parse!(@arguments, into: found)
    found
  end

  def parser
    OptionParser.new do |parser|
      PATHS.each { |key| parser.on("--#{key} PATH", String) { |value| File.expand_path(value) } }
      FLAGS.each { parser.on(*it) }
    end
  end

  def compare
    before, after = @arguments.map { JSON.parse(File.read(it)) }
    emit(Assay::Comparison.new(before, after).markdown)
  end

  def emit(text)
    options[:out] ? File.write(options[:out], text) : @io.puts(text)
    0
  end

  def gate(data) = options[:gate] ? Assay::Gate.new(data).check(@io) : 0

  def score
    bundle = Assay::Bundle.new(options[:kata], File.join(work, "bundle"), shell, elegant: options[:elegant]).prepare
    options[:only].each_with_object({ "kata" => bundle.to_h }) { |name, data| data[name] = section(name, bundle) }
  end

  def work = options[:work] || File.join(Assay::ROOT, "..", "tmp", "eval", File.basename(options[:kata]))

  def section(name, bundle)
    @io.puts("assay: #{name}")
    return corpora(bundle) if name == "corpora"
    BUILDERS.fetch(name).call(bundle, File.join(work, name), options).to_h
  end

  def corpora(bundle)
    queue = Queue.new.tap { |pending| specs.each { pending << it } }.tap(&:close)
    results = {}
    Array.new(options[:jobs]) { start(queue, results, bundle) }.each(&:join)
    specs.to_h { [it["name"], results.fetch(it["name"])] }
  end

  def start(queue, results, bundle)
    Thread.new do # rubocop:disable ThreadSafety/NewThread -- each thread only waits on a child rubocop process
      while (spec = queue.pop)
        results[spec["name"]] = measure(spec, bundle)
      end
    end
  end

  def measure(spec, bundle)
    name = spec["name"]
    result = Assay::Corpus.new(spec, bundle, File.join(work, "corpora", name), shell).to_h
    @io.puts("assay: corpus #{name} done")
    result
  end

  def specs = @_specs ||= YAML.safe_load_file(options[:list] || CORPORA).map { it.merge("cache" => cache) }

  def cache = options[:corpora] || File.join(Assay::ROOT, "..", "tmp", "eval", "corpora")

  def shell = Assay::Shell.new(@env.slice(*KEPT))

  def write(data)
    out = options[:out] || File.join(Assay::ROOT, "results", "latest.json")
    FileUtils.mkdir_p(File.dirname(out))
    File.write(out, "#{JSON.pretty_generate(data)}\n")
    File.write(out.sub(/\.json\z/, ".md"), Assay::Comparison.new(nil, data).markdown)
    @io.puts("assay: wrote #{out}")
  end
end
