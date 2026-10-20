# frozen_string_literal: true

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

  def correct(flag, picked)
    Dir.mktmpdir("kata-autocorrect") do |root|
      lib = plant(root, picked)
      errors = quietly { RuboCop::CLI.new.run([flag, "--cache", "false", lib]) }
      yield(picked.keys.to_h { [it, File.read(File.join(lib, it))] }, errors)
    end
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

  it "keeps a dash-form magic comment through rubocop -A" do
    shape = { "table.rb" => "# frozen-string-literal: true\n\nmodule Shelf\n  TABLE = { a: [1] }.freeze\nend\n" }
    correct("-A", shape) { |fixed, _| expect(fixed.fetch("table.rb")).to(match(/\A# frozen.string.literal: true/)) }
  end
end
