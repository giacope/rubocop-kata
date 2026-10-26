# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::IoDiscipline, :config) do
  let(:ruby_version) { 3.4 }
  let(:cop_config) do
    YAML.load_file("config/default.yml", aliases: true).fetch("Kata/IoDiscipline").merge("OwnedPaths" => [])
  end

  def fixed(call, noun)
    "`#{call}` reaches a #{noun} written into the code: hidden I/O. " \
      "Inject the #{noun}, or the object that reaches it, and act through that."
  end

  def global(name, held)
    "Inject `#{name}` (`def initialize(#{held}: #{name})`) and send through it; a global reached from a method " \
      "is hidden I/O."
  end

  it "flags bare output calls, naming the stream the class holds" do
    expect_offense(<<~RUBY)
      class Report
        def initialize(out) = @out = out
        def show
          puts "report"
          ^^^^^^^^^^^^^ Write through the injected `@out`, not bare `puts`.
          warn "oops"
          ^^^^^^^^^^^ Write through the injected `@out`, not bare `warn`.
          pp value
          ^^^^^^^^ Write through the injected `@out`, not bare `pp`.
          p value
          ^^^^^^^ Write through the injected `@out`, not bare `p`.
        end
      end
    RUBY
  end

  # pundit.rb: a module-level `warn` has no stream to write through yet.
  it "names the seam to add where nothing is injected" do
    expect_offense(<<~RUBY)
      def report = puts
                   ^^^^ Inject the stream `puts` writes to (`def initialize(io: $stdout)`) and write through it.
      module Pundit
        def self.deprecate = warn("old")
                             ^^^^^^^^^^^ Inject the stream `warn` writes to (`def initialize(io: $stderr)`) and write through it.
      end
    RUBY
  end

  it "allows writing through a receiver" do
    expect_no_offenses(<<~RUBY)
      def report
        @io.puts "report"
        io.p(value)
        Kernel.warn("x")
      end
    RUBY
  end

  it "flags print and printf with something to print" do
    expect_offense(<<~RUBY)
      def show
        print "."
        ^^^^^^^^^ Inject the stream `print` writes to (`def initialize(io: $stdout)`) and write through it.
        printf("%d", 1)
        ^^^^^^^^^^^^^^^ Inject the stream `printf` writes to (`def initialize(io: $stdout)`) and write through it.
        print
        printf { "row" }
      end
    RUBY
  end

  # The V1 conformance case P33: an audit record that writes a log file, the Rails log and a webhook.
  it "flags a file, network or shell call whose target is written into the code" do
    expect_offense(<<~RUBY, path: fixed("File.write", "path"), url: fixed("Net::HTTP.post", "URL"))
      class Audit
        def record
          File.write("log/audit.log", "\#{@event}.", mode: @mode)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{path}
          Net::HTTP.post(URI("https://hooks.example.com/audit"), @event)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{url}
        end
      end
    RUBY
  end

  it "names what each call reaches: a path, a URL or a command" do
    reached = {
      dir: fixed("Dir.pwd", "path"), yaml: fixed("YAML.load_file", "path"), faraday: fixed("Faraday.get", "URL"),
      system: fixed("system", "command"), popen: fixed("IO.popen", "command"),
      open3: fixed("Open3.capture2", "command"), rm: fixed("FileUtils.rm_rf", "path"), root: fixed("File.read", "path")
    }
    expect_offense(<<~RUBY, **reached)
      def sync
        Dir.pwd
        ^^^^^^^ %{dir}
        YAML.load_file("config/rates.yml")
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{yaml}
        Faraday.get("https://api.example.com")
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{faraday}
        system("git", "fetch")
        ^^^^^^^^^^^^^^^^^^^^^^ %{system}
        IO.popen(["git", "log"])
        ^^^^^^^^^^^^^^^^^^^^^^^^ %{popen}
        Open3.capture2("ls")
        ^^^^^^^^^^^^^^^^^^^^ %{open3}
        FileUtils.rm_rf("tmp/cache")
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{rm}
        File.read(Rails.root.join("config", format("%s.yml", "rates")))
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{root}
      end
    RUBY
  end

  it "flags a shell command in backticks, naming its program" do
    expect_offense(<<~RUBY, git: fixed("%x(git)", "command"), blank: fixed("%x()", "command"))
      def head
        `git rev-parse HEAD`
        ^^^^^^^^^^^^^^^^^^^^ %{git}
        %x(\#{"ls"})
        ^^^^^^^^^^^ %{blank}
      end
    RUBY
  end

  it "passes a call whose target holds a variable, an instance variable or a method's value" do
    expect_no_offenses(<<~RUBY)
      class Disk
        def write(text)
          File.write(@path, text)
          File.open(path, "a") { it.write(text) }
          FileUtils.mkdir_p(File.dirname(text))
          Net::HTTP.get(@uri)
          system("git", "fetch", text)
          `git log \#{@ref}`
          Dir.glob("\#{root}/**/*.rb").each { |file| File.read(file) }
          File.exist?(self.class.path)
        end
      end
    RUBY
  end

  # rubocop-kata's own Kit reads its skill through a constant anchored on __dir__.
  it "passes a path anchored on the source file, directly or through a constant" do
    expect_no_offenses(<<~RUBY)
      class Kit
        SOURCE = File.expand_path("../SKILL.md", __dir__)

        def run
          File.read(SOURCE)
          File.read(__FILE__)
          File.readlines(File.join(__dir__, "words.txt"))
        end
      end
    RUBY
  end

  it "flags a path a constant of the file writes into the code" do
    expect_offense(<<~RUBY, message: fixed("File.write", "path"), joined: fixed("File.read", "path"))
      class Audit
        LOG = "log/audit.log"

        def record = File.write(LOG, "x")
                     ^^^^^^^^^^^^^^^^^^^^ %{message}
        def check = File.read(File.join(LOG, "x"))
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{joined}
      end
    RUBY
  end

  # rubocop-kata's Survey globs under the root it was given; its Entries read Profile::BASE.
  it "passes a glob under an injected base, and a constant another file defines" do
    expect_no_offenses(<<~RUBY)
      class Survey
        def gems = Dir.glob("*.gemspec", base: @root)
        def tree = Dir.chdir("lib", chdir: root)
        def shipped = YAML.load_file(Profile::BASE)
        def other = File.read(SETTINGS)
      end
    RUBY
  end

  # kimera's worker fleet: its own private `spawn` starts a worker.
  it "passes a command name the file defines, or one called without arguments" do
    expect_no_offenses(<<~RUBY)
      class Fleet
        def bootstrap = 2.times { spawn(:worker) }
        def replace = system

        private

        def spawn(kind) = kind
      end
    RUBY
  end

  it "passes path arithmetic and the other methods of a listed constant" do
    expect_no_offenses(<<~RUBY)
      def paths
        File.join("a", "b")
        File.basename("log/a.log")
        File.expand_path("lib")
        IO.select([@socket])
        Excon.defaults
        CSV.generate { it << [1] }
      end
    RUBY
  end

  it "flags a global stream or service reached from a method, naming the seam" do
    globals = {
      out: global("$stdout", "io"), log: global("Rails.logger", "logger"), cache: global("Rails.cache", "cache"),
      err: global("STDERR", "io")
    }
    expect_offense(<<~RUBY, **globals)
      class Audit
        def record
          $stdout.puts "x"
          ^^^^^^^ %{out}
          Rails.logger.info("audit")
          ^^^^^^^^^^^^ %{log}
          Rails.cache.fetch("audit") { 1 }
          ^^^^^^^^^^^ %{cache}
          Logger.new(STDERR)
                     ^^^^^^ %{err}
        end
      end
    RUBY
  end

  # Kata/ClockDiscipline reads `now || Time.now` the same way: the default is the seam, the fallback is not.
  it "passes a global as a parameter default, not as the fallback for one" do
    expect_offense(<<~RUBY, message: global("$stderr", "io"))
      class Audit
        def initialize(log = Rails.logger, io: $stdout, out: nil)
          @log = log
          @io = io
          @out = out || $stderr
                        ^^^^^^^ %{message}
        end
      end
    RUBY
  end

  # hashie's railtie, ahoy's engine: a framework's boot hooks wire the globals in.
  it "takes a framework's boot hooks for the boot layer" do
    expect_no_offenses(<<~RUBY)
      class Railtie < Rails::Railtie
        initializer "hashie.logger" do
          Hashie.logger = Rails.logger
        end
        config.after_initialize { File.read("config/x.yml") }
        ActiveSupport.on_load(:active_record) { $stdout.sync = true }
      end
    RUBY
  end

  # rubycritic's Cli::Options builds its own Options::File, not Ruby's.
  it "leaves a constant the project defines in the nesting, and reads ::File as Ruby's" do
    expect_offense(<<~RUBY, message: fixed("File.read", "path"))
      module Cli
        class Options
          class File
          end

          def initialize
            @file = File.new
            ::File.read("config.yml")
            ^^^^^^^^^^^^^^^^^^^^^^^^^ %{message}
          end
        end
      end
    RUBY
  end

  it "leaves other bare calls alone" do
    expect_no_offenses(<<~RUBY)
      print_report
      putc "x"
    RUBY
  end

  it "leaves a p that cannot be Kernel#p: one given a block, or no argument" do
    expect_no_offenses(<<~RUBY)
      def show
        p(class: "empty") { "No senders" }
        p { "text" }
        where { { p[:owner] => 1 } }
      end
    RUBY
  end

  it "still flags p printing a value" do
    expect_offense(<<~RUBY)
      def show
        p(value)
        ^^^^^^^^ Inject the stream `p` writes to (`def initialize(io: $stdout)`) and write through it.
        p value, other
        ^^^^^^^^^^^^^^ Inject the stream `p` writes to (`def initialize(io: $stdout)`) and write through it.
      end
    RUBY
  end

  # beis's lib/scripts/import_forecasts.rb: Kata/EnvDiscipline and Kata/ClockDiscipline call it the boot layer too.
  it "takes code outside every class, module and method for a script's boot layer" do
    expect_no_offenses(<<~RUBY)
      warn "Could not find fund" unless ENV.key?("FUND")
      ARGV.each { puts it }
      p(value)
      File.write("report.txt", `git log`)
      $stdout.sync = true
    RUBY
  end

  # rubycritic: `Options::File` lives in its own file under lib/.
  context "with the project's files" do
    include ProjectFiles

    let(:setting) { { "Kata/IoDiscipline" => cop_config.merge("OwnedPaths" => ["lib/**/*.rb"]) } }

    it "leaves a constant the project defines in another file" do
      files = {
        "lib/cli/options/file.rb" => "module Cli\n  class Options\n    class File\n    end\n  end\nend\n",
        "lib/cli/options.rb" => "module Cli\n  class Options\n    def read = File.read(\"x\")\n  end\nend\n"
      }
      expect(project_offenses(files, "lib/cli/options.rb")).to(be_empty)
    end
  end

  context "with the shipped defaults" do
    let(:root) { File.expand_path("../../../..", __dir__) }
    let(:shipped) { YAML.load_file(File.join(root, "config/default.yml"), aliases: true).slice("Kata/IoDiscipline") }
    let(:config) { RuboCop::Config.new(shipped, File.join(root, ".rubocop.yml")) }

    it "exempts the boot layer and the test suite, and nothing else" do
      cop = described_class.new(config)
      paths = %w[
        exe/tool bin/setup script/seed config/boot.rb lib/tasks/a.rake Rakefile spec/a_spec.rb test/a_test.rb lib/a.rb
      ]
      expect(paths.select { cop.relevant_file?(File.join(root, it)) }).to(eq(%w[lib/a.rb]))
    end
  end
end
