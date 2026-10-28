# frozen_string_literal: true

require "json"
require "tmpdir"
require "stringio"

RSpec.describe(RuboCop::Kata::Plugin) do
  let(:shapes) do
    {
      "errors.rb" => <<~RUBY,
        # frozen_string_literal: true

        module Shelf
          NAMES = [
            (Missing = Class.new(StandardError)).name,
            (Broken = Class.new(StandardError)).name
          ].freeze
        end
      RUBY
      "transaction.rb" => <<~RUBY,
        # frozen_string_literal: true

        module Shelf
          class Transaction
            def run
              yield
            rescue StandardError => e
              @failed = true
            ensure
              finish(e)
            end

            def finish(failure) = failure
          end
        end
      RUBY
      "outcome.rb" => <<~RUBY,
        # frozen_string_literal: true

        module Shelf
          class Outcome
            def label
              error = "none"
              begin
                Integer("x")
              rescue ArgumentError => e
                e.message
              end
              error
            end
          end
        end
      RUBY
      "label.rb" => <<~RUBY,
        # frozen_string_literal: true

        module Shelf
          class Label
            #: (String) -> void
            def initialize(text)
              @text = text
            end

            #: -> String
            def text = @text
          end
        end
      RUBY
      "box.rb" => <<~RUBY,
        # frozen_string_literal: true

        module Shelf
          module Box
            def self.included(host)
              host.module_exec do
                def first
                  1
                end

                def second
                  2
                end
              end
            end
          end
        end
      RUBY
      "functions.rb" => <<~RUBY
        # frozen_string_literal: true

        module Shelf
          module Functions
            def install(name)
              create_function(
                name, <<~SQL, returns: :trigger)
                  RETURN NULL;
                SQL
            end
          end
        end
      RUBY
    }
  end

  def index
    elements = "options.key?(:index_prefix) ? options[:index_prefix] : Shelf.prefix, model_name.plural, Shelf.env"
    <<~RUBY
      # frozen_string_literal: true

      module Shelf
        module Model
          def index_name
            @index_name ||= begin
              [#{elements}, Shelf.suffix].compact.join("_")
            end
          end
        end
      end
    RUBY
  end

  def streams
    <<~RUBY
      # frozen_string_literal: true

      module Shelf
        module Streams
          def remove_later(*streamables, target: self, **rendering)
            Turbo::StreamsChannel.broadcast_remove_later_to(*streamables, **extract_options_and_add_target(rendering, target:))
          end

          def perform(stream, action:, target:, **rendering)
            Turbo::StreamsChannel.broadcast_action_to(stream, action:, target:, html: @html, sound: @sound, layout: @layout, **rendering)
          end
        end
      end
    RUBY
  end

  def correct(flag, picked)
    Dir.mktmpdir("kata-autocorrect") do |root|
      lib = plant(root, picked)
      errors = quietly { RuboCop::CLI.new.run([flag, "--cache", "false", lib]) }
      yield(picked.keys.to_h { [it, File.read(File.join(lib, it))] }, errors, lib)
    end
  end

  def checked(lib)
    report = File.join(File.dirname(lib), "report.json")
    quietly { RuboCop::CLI.new.run(["--cache", "false", "--format", "json", "--out", report, lib]) }
    JSON.parse(File.read(report)).fetch("files").flat_map { |file| file.fetch("offenses").map { it.fetch("cop_name") } }
  end

  def plant(root, picked)
    lib = File.join(root, "lib")
    FileUtils.mkdir_p(lib)
    picked.each { |name, source| File.write(File.join(lib, name), source) }
    File.write(File.join(root, ".rubocop.yml"), "plugins:\n  - rubocop-kata\n\nAllCops:\n  TargetRubyVersion: 3.4\n")
    lib
  end

  def quietly
    streams = [$stdout, $stderr]
    $stdout = StringIO.new
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stdout, $stderr = streams
  end

  def parses?(source) = Prism.parse(source).success?

  it "keeps every file rubocop -a corrects parseable, with no infinite loop" do
    correct("-a", shapes) do |fixed, errors|
      expect([fixed.values.reject { parses?(it) }, errors.scan(/infinite loop/i)]).to(eq([[], []]))
    end
  end

  it "keeps a class built inside an expression an expression" do
    correct("-a", shapes.slice("errors.rb")) { |fixed, _| expect(fixed.fetch("errors.rb")).to(include("Class.new")) }
  end

  it "renames no rescue variable, whose other readers it would leave behind" do
    picked = shapes.slice("transaction.rb", "outcome.rb")
    correct("-a", picked) { |fixed, _| expect(fixed.values.grep(/=> e$/).size).to(eq(2)) }
  end

  it "keeps RBS inline signatures as signatures" do
    correct("-a", shapes.slice("label.rb")) { |fixed, _| expect(fixed.fetch("label.rb").scan("#: ").size).to(eq(2)) }
  end

  it "moves the closer below a heredoc its line opens" do
    correct("-a", shapes.slice("functions.rb")) do |fixed, _|
      expect(fixed.fetch("functions.rb")).to(include("SQL\n      )\n"))
    end
  end

  # searchkick: `-a` left `].compact.join("_")` three columns in, under a `[` eight columns in.
  it "puts a closing bracket a merged pass drifted back at the indent of its opener's line" do
    correct("-a", "index.rb" => index) { |fixed, _| expect(fixed.fetch("index.rb")).to(include("\n        ].compact")) }
  end

  # turbo-rails: `-a` left a double-splat argument it broke onto a line of its own at column 0, and
  # Elegant/MonotonicIndents then reported the line after it, which -a could not correct (R6B5-KA1).
  it "indents a double-splat argument it moves to a line of its own, and the check accepts what it wrote" do
    correct("-a", "streams.rb" => streams) do |fixed, _, lib|
      expect([fixed.fetch("streams.rb").scan(/^ {8}\*\*/).size, checked(lib)]).to(eq([2, []]))
    end
  end

  # sshkit: -a closed the blank lines around each `module Formatter` reopening, and Kata/GoodModuleName judged
  # every reopening it moved, from the lines the project held before -a wrote the files (R6B6-K2).
  it "reports after -a what a fresh check of the corrected files reports" do
    Dir.mktmpdir("kata-autocorrect") do |root|
      remaining = reported(plant(root, formatters), "-a")
      expect([remaining, remaining.size]).to(eq([fresh(File.join(root, "lib")), 1]))
    end
  end

  def formatters
    opened = "module Shelf\n\n  module Formatter\n\n    class %s < Abstract\n    end\n\n  end\n\nend\n"
    abstract = "module Shelf\n  module Formatter\n    class Abstract\n    end\n  end\nend\n"
    picked = %w[Dot Pretty Plain].to_h { ["#{it.downcase}.rb", format(opened, it)] }
    picked.merge("abstract.rb" => abstract).transform_values { "# frozen_string_literal: true\n\n#{it}" }
  end

  def reported(lib, *flags)
    report = File.join(File.dirname(lib), "report.json")
    quietly { RuboCop::CLI.new.run([*flags, "--cache", "false", "--format", "json", "--out", report, lib]) }
    JSON.parse(File.read(report)).fetch("files").flat_map do |file|
      named = File.basename(file.fetch("path"))
      file.fetch("offenses").reject { it["corrected"] }.map { [named, it.fetch("cop_name")] }
    end
  end

  def fresh(lib)
    Dir.mktmpdir("kata-fresh") do |root|
      FileUtils.cp_r(lib, root)
      FileUtils.cp(File.join(File.dirname(lib), ".rubocop.yml"), root)
      reported(File.join(root, "lib"))
    end
  end

  context "with the -a post-check" do
    let(:sql) { "# frozen_string_literal: true\n\nSQL = \"SELECT *   \nFROM t  \nWHERE a\"\n" }
    let(:heredoc) { "# frozen_string_literal: true\n\ndef salt\n  <<END\nCASE\n  WHEN a THEN 1\n  END\nEND\nend\n" }
    let(:vouching) { "\nLayout/HeredocIndentation:\n  SafeAutoCorrect: true\n" }
    let(:stray) { kept_line("changed the literal on line 3", "Layout/TrailingWhitespace") }

    before do
      skip("RuboCop #{RuboCop::Version::STRING} writes each pass itself") unless
        RuboCop::Runner.instance_method(:finalize_corrections).super_method
    end

    def guarded(flags, source, setting = "", input: "")
      Dir.mktmpdir("kata-safeguard") do |root|
        path = File.join(plant(root, { "sample.rb" => source }), "sample.rb")
        File.write(File.join(root, ".rubocop.yml"), setting, mode: "a")
        node = File.stat(path).ino
        status, output, errors = fed(input) { Dir.chdir(root) { RuboCop::CLI.new.run([*flags, "--cache", "false"]) } }
        yield(File.read(path), errors, output, status, File.stat(path).ino == node)
      end
    end

    def fed(input)
      streams = [$stdin, $stdout, $stderr]
      $stdin = StringIO.new(input)
      $stdout = StringIO.new
      $stderr = StringIO.new
      [yield, $stdout.string, $stderr.string]
    ensure
      $stdin, $stdout, $stderr = streams
    end

    def ran(options, source)
      Dir.mktmpdir("kata-safeguard") do |root|
        path = File.join(plant(root, { "sample.rb" => source }), "sample.rb")
        runner = RuboCop::Runner.new(options.merge(formatters: [["quiet"]]), RuboCop::ConfigStore.new)
        quietly { Dir.chdir(root) { runner.run(["lib"]) } }
        File.read(path)
      end
    end

    def kept_line(flaw, cops) = "rubocop-kata: kept lib/sample.rb as it was: -a would have #{flaw} (refused: #{cops})\n"

    it "keeps a file whose corrections would change a string's text as it was, untouched, and says why on one line" do
      guarded(%w[-a lib], sql) do |kept, errors, _, _, untouched|
        expect([kept, untouched, errors]).to(eq([sql, true, stray]))
      end
    end

    # `rubocop -a && git diff --exit-code` passed on a file -a had kept.
    it "reports a kept file's offenses as uncorrected, and exits as a plain run on it would" do
      guarded(%w[-a --format json lib], sql) do |_, _, output, status|
        found = JSON.parse(output).dig("files", 0, "offenses").map { it.values_at("cop_name", "corrected") }
        expect([found, status]).to(eq([[["Layout/TrailingWhitespace", false]] * 2, 1]))
      end
    end

    it "checks rubocop -x as it checks -a" do
      guarded(%w[-x lib], sql) { |kept, errors| expect([kept, errors]).to(eq([sql, stray])) }
    end

    it "runs no correction -a holds back under rubocop -x either" do
      guarded(%w[-x lib], heredoc) { |kept, errors| expect([kept, errors]).to(eq([heredoc, ""])) }
    end

    it "leaves a plain run's summary alone" do
      guarded(%w[lib], sql) { |_, _, output| expect(output).to(include("2 offenses autocorrectable")) }
    end

    # The language server's "fix all" asks for every correction, as -A does.
    it "leaves a runner told its corrections need not be safe to write what it corrects" do
      expect(ran({ autocorrect: true, safe_autocorrect: false }, sql)).to(include("SELECT *\n"))
    end

    it "keeps a file a correction the project vouched for would leave unparsable" do
      guarded(%w[-a lib], heredoc, vouching) do |kept, errors|
        expect([kept, errors]).to(eq([heredoc, kept_line("made it unparsable", "Layout/HeredocIndentation")]))
      end
    end

    it "hands rubocop -a --stdin its input back, reports it uncorrected and leaves the file alone" do
      guarded(%w[-a --stdin lib/sample.rb], "", input: sql) do |disk, errors, output|
        facts = [disk, output.end_with?("=\n#{sql}"), output.scan("Layout/TrailingWhitespace").size, errors]
        expect(facts).to(eq(["", true, 2, stray]))
      end
    end

    it "leaves rubocop -A to write what it corrects" do
      guarded(%w[-A lib], sql) do |fixed, errors, _|
        expect([fixed.include?("SELECT *\n"), errors]).to(eq([true, ""]))
      end
    end

    # A plugin may add a Ruby extractor (Runner.ruby_extractors); RuboCop then writes each pass to the file itself.
    context "when another Ruby extractor is registered" do
      around do |example|
        extractor = ->(_) {}
        RuboCop::Runner.ruby_extractors.unshift(extractor)
        example.run
      ensure
        RuboCop::Runner.ruby_extractors.delete(extractor)
      end

      it "checks the file RuboCop wrote itself, and puts the original back when the check fails" do
        guarded(%w[-a lib], sql) { |kept, errors| expect([kept, errors]).to(eq([sql, stray])) }
      end

      it "leaves the corrections RuboCop wrote itself when they pass" do
        guarded(%w[-a lib], "A = 'é'\n") { |fixed, errors| expect([fixed, errors]).to(eq(["A = \"é\"\n", ""])) }
      end
    end
  end

  it "keeps a dash-form magic comment through rubocop -A" do
    shape = { "table.rb" => "# frozen-string-literal: true\n\nmodule Shelf\n  TABLE = { a: [1] }.freeze\nend\n" }
    correct("-A", shape) { |fixed, _| expect(fixed.fetch("table.rb")).to(match(/\A# frozen.string.literal: true/)) }
  end
end
