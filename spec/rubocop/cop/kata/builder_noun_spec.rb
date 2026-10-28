# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::BuilderNoun, :config) do
  let(:cop_config) { { "BannedPrefixes" => %w[get calculate], "AllowedNames" => %w[get_callbacks] } }

  it "flags verb-prefixed builders" do
    expect_offense(<<~RUBY)
      def calculate_total
          ^^^^^^^^^^^^^^^ A builder is named for what it returns: `total`, not `calculate_total`.
      end
      def self.get_name
               ^^^^^^^^ A builder is named for what it returns: `name`, not `get_name`.
      end
    RUBY
  end

  # rubycritic's private `generate_for(rating)`, called bare: `for(rating)` would open a for loop (R6B6-K7).
  it "proposes no name that is a keyword or does not parse as a call where the method is called" do
    expect_offense(<<~RUBY)
      def get_for(rating)
          ^^^^^^^ A builder is named for what it returns, not `get_for`: name it for the object it answers.
      end
      def get_module(name)
          ^^^^^^^^^^ A builder is named for what it returns, not `get_module`: name it for the object it answers.
      end
      def get_class
          ^^^^^^^^^ A builder is named for what it returns, not `get_class`: name it for the object it answers.
      end
      def get_end
          ^^^^^^^ A builder is named for what it returns, not `get_end`: name it for the object it answers.
      end
      def get_if
          ^^^^^^ A builder is named for what it returns, not `get_if`: name it for the object it answers.
      end
      def get_2fa
          ^^^^^^^ A builder is named for what it returns, not `get_2fa`: name it for the object it answers.
      end
      def get_formula
          ^^^^^^^^^^^ A builder is named for what it returns: `formula`, not `get_formula`.
      end
    RUBY
  end

  it "allows a name an external API dictates" do
    expect_no_offenses(<<~RUBY)
      def get_callbacks
      end
    RUBY
  end

  it "allows nouns and bare verbs" do
    expect_no_offenses(<<~RUBY)
      def total
      end
      def calculate
      end
      def getaway
      end
    RUBY
  end

  it "leaves a method that calls super to its ancestor's name" do
    expect_no_offenses(<<~RUBY)
      def calculate_total(*)
        super + 1
      end
    RUBY
  end

  # padrino-gen, flipper's generators: a step that writes a file returns no built object.
  context "with commands" do
    let(:ruby_version) { 3.4 }
    let(:cop_config) { { "BannedPrefixes" => %w[generate], "Commands" => %w[File.write FileUtils invoke] } }

    # aasm's `invoke … unless model_exists?`, madmin's `route` in both branches of an `if`.
    it "leaves a method that issues a command anywhere in its body to its verb" do
      expect_offense(<<~RUBY)
        def generate_initializer = File.write("config/shelf.rb", "Shelf.start")
        def generate_tree(dir) = FileUtils.mkdir_p(dir)
        def generate_active_record
          say "creating"
          invoke "flipper:active_record"
        end
        def generate_model
          invoke "active_record:model", [name] unless model_exists?
        end
        def generate_copy = files.map { File.write(it, "") }
        def generate_report = File.read("report.txt")
            ^^^^^^^^^^^^^^^ A builder is named for what it returns: `report`, not `generate_report`.
        def generate_log = logger.write("x")
            ^^^^^^^^^^^^ A builder is named for what it returns: `log`, not `generate_log`.
        def generate_site(dir) = FileUtils.cd(dir) { build }
      RUBY
    end
  end

  # resque's `generate_failure_ids?`, simple_form's `generate_label_for_attribute?`: a question returns a boolean.
  it "leaves a predicate alone, since it builds nothing" do
    expect_no_offenses(<<~RUBY)
      def get_failure_ids?(options)
        options.key?(:ids)
      end
    RUBY
  end

  # madmin's generators: Rails runs each public method of a generator in turn, a step whatever it returns.
  context "with a generator" do
    let(:ruby_version) { 3.4 }
    let(:cop_config) do
      { "BannedPrefixes" => %w[generate], "Commands" => [], "StepSuperclasses" => %w[Rails::Generators::Base Thor] }
    end

    it "leaves its public steps to their verbs, and judges its helpers and other classes" do
      expect_offense(<<~RUBY)
        module Shelf
          class BaseGenerator < ::Rails::Generators::Base
          end

          class InstallGenerator < BaseGenerator
            def generate_routes = resources.each { call_generator(it) }

            def self.generate_banner = "shelf"
                     ^^^^^^^^^^^^^^^ A builder is named for what it returns: `banner`, not `generate_banner`.

            private

            def generate_field(name) = name
                ^^^^^^^^^^^^^^ A builder is named for what it returns: `field`, not `generate_field`.
          end

          class Command < Thor
            def generate_config = say("written")
          end

          class Report
            def generate_summary = 1
                ^^^^^^^^^^^^^^^^ A builder is named for what it returns: `summary`, not `generate_summary`.
          end
        end
      RUBY
    end
  end

  context "with the project's library" do
    include TabledCop

    let(:root) { Dir.mktmpdir("kata-builders") }
    let(:cop) do
      shipped = { "Kata/BuilderNoun" => { "BannedPrefixes" => %w[get], "OwnedPaths" => ["lib/**/*.rb"] } }
      described_class.new(RuboCop::Config.new(shipped, File.join(root, ".rubocop.yml")))
    end

    before do
      FileUtils.mkdir_p(File.join(root, "lib"))
      library = "class Chain\n  def held(owner) = owner.__send__(:get_callbacks)\nend\n"
      File.write(File.join(root, "lib", "chain.rb"), library)
      File.write(File.join(root, "lib", "adapter.rb"), "module Adapter\n  def get_all = 1\nend\n")
    end

    after { FileUtils.rm_rf(root) }

    # kimera's schemata_spec mirrors ActiveSupport's private get_callbacks.
    it "leaves a stand-in for a message the project sends but never defines to the caller's name" do
      expect(offenses("def get_callbacks(name) = name\ndef get_name = 1\n").map(&:line)).to(eq([2]))
    end

    # flipper: each adapter implements Flipper::Adapter#get_all.
    it "reports a name once, where the protocol chose it, not in each implementation" do
      source = "class Memory\n  include Adapter\n  def get_all = {}\n  def get_one = 1\nend\n"
      expect(offenses(source).map(&:line)).to(eq([4]))
    end
  end
end
