# frozen_string_literal: true

require "optparse"

class Assay::Session
  SECTIONS = %w[settings cases names cli corpora].freeze
  KEPT = %w[PATH HOME GEM_HOME GEM_PATH LANG LC_ALL TMPDIR SSL_CERT_FILE HTTPS_PROXY HTTP_PROXY NO_PROXY].freeze
  USAGE = "usage: eval/run --kata PATH [--out FILE] [--only LIST] | eval/run --compare BEFORE AFTER [--out FILE]"

  def initialize(arguments, io:, env:)
    @arguments = arguments
    @io = io
    @env = env
  end

  def run
    options = parse
    return compare(options) if options[:compare]
    return usage unless options[:kata]
    write(options, score(options))
    0
  end

  private

  def usage
    @io.puts(USAGE)
    1
  end

  def parse
    options = { only: SECTIONS, jobs: 4, elegant: "0.8.0" }
    OptionParser.new do |parser|
      parser.on("--kata PATH") { options[:kata] = File.expand_path(it) }
      parser.on("--out FILE") { options[:out] = File.expand_path(it) }
      parser.on("--work DIR") { options[:work] = File.expand_path(it) }
      parser.on("--corpora DIR") { options[:cache] = File.expand_path(it) }
      parser.on("--only LIST", Array) { options[:only] = it }
      parser.on("--jobs N", Integer) { options[:jobs] = it }
      parser.on("--elegant VERSION") { options[:elegant] = it }
      parser.on("--reveal") { options[:reveal] = true }
      parser.on("--compare") { options[:compare] = true }
    end.parse!(@arguments)
    options
  end

  def compare(options)
    before, after = @arguments.map { JSON.parse(File.read(it)) }
    text = Assay::Comparison.new(before, after).markdown
    options[:out] ? File.write(options[:out], text) : @io.puts(text)
    0
  end

  def score(options)
    work = options[:work] || File.join(Assay::ROOT, "..", "tmp", "eval", File.basename(options[:kata]))
    bundle = Assay::Bundle.new(options[:kata], File.join(work, "bundle"), shell, elegant: options[:elegant]).prepare
    data = { "kata" => bundle.identity }
    options[:only].each { |section| data[section] = section(section, bundle, work, options) }
    data
  end

  def section(name, bundle, work, options)
    @io.puts("assay: #{name}")
    case name
    when "settings" then Assay::Settings.new(bundle, File.join(work, "settings")).result
    when "cases" then Assay::Snippets.new(bundle, File.join(work, "cases"), Dir[File.join(Assay::ROOT, "cases", "*.yml")].sort).result
    when "names" then Assay::Lexicon.new(bundle, File.join(work, "names"), File.join(Assay::ROOT, "names.yml"), reveal: options[:reveal]).result
    when "cli" then Assay::Console.new(bundle, File.join(work, "cli"), File.join(Assay::ROOT, "cli.yml")).result
    when "corpora" then corpora(bundle, work, options)
    end
  end

  def corpora(bundle, work, options)
    cache = options[:cache] || File.join(Assay::ROOT, "..", "tmp", "eval", "corpora")
    specs = YAML.safe_load_file(File.join(Assay::ROOT, "corpora.yml"))
    queue = Queue.new
    specs.each { queue << it }
    queue.close
    results = {}
    Array.new(options[:jobs]) do
      Thread.new do
        while (spec = queue.pop)
          corpus = Assay::Corpus.new(spec, bundle, cache: cache, work: File.join(work, "corpora", spec["name"]), shell: shell)
          results[spec["name"]] = corpus.result
          @io.puts("assay: corpus #{spec["name"]} done")
        end
      end
    end.each(&:join)
    specs.to_h { [it["name"], results.fetch(it["name"])] }
  end

  def shell = Assay::Shell.new(@env.slice(*KEPT))

  def write(options, data)
    out = options[:out] || File.join(Assay::ROOT, "results", "latest.json")
    FileUtils.mkdir_p(File.dirname(out))
    File.write(out, "#{JSON.pretty_generate(data)}\n")
    File.write(out.sub(/\.json\z/, ".md"), Assay::Board.new(data).markdown)
    @io.puts("assay: wrote #{out}")
  end
end
