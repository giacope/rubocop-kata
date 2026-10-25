# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::IoDiscipline, :config) do
  let(:ruby_version) { 3.4 }

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
      @io.puts "report"
      $stderr.puts "oops"
      io.p(value)
      Kernel.warn("x")
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
      p(class: "empty") { "No senders" }
      p { "text" }
      where { { p[:owner] => 1 } }
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
    RUBY
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
