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

  context "with CheckEveryBuilder, the strict profile's reading of every builder" do
    let(:ruby_version) { 3.4 }
    let(:cop_config) do
      RuboCop::ConfigLoader.default_configuration.for_cop("Kata/BuilderNoun").merge("CheckEveryBuilder" => true)
    end

    # V1 P06: `build_summary` passed, since only get/calculate/compute/retrieve/generate were banned.
    it "names every builder for what it returns, whatever verb of making or getting it starts with" do
      expect_offense(<<~RUBY)
        class Order
          def build_summary = "\#{subtotal} + \#{tax}"
              ^^^^^^^^^^^^^ A builder is named for what it returns: `summary`, not `build_summary`.
          def find_line(sku) = @lines.find { it.sku == sku }
              ^^^^^^^^^ A builder is named for what it returns: `line`, not `find_line`.
          def load_config = @config ||= YAML.load_file("shop.yml")
              ^^^^^^^^^^^ A builder is named for what it returns: `config`, not `load_config`.
          def self.make_point(x, y) = new(x, y)
                   ^^^^^^^^^^ A builder is named for what it returns: `point`, not `make_point`.
          def parse_date(text) = Date.parse(text)
              ^^^^^^^^^^ A builder is named for what it returns: `date`, not `parse_date`.
          def build_rows
              ^^^^^^^^^^ A builder is named for what it returns: `rows`, not `build_rows`.
            rows = []
            rows << header
            rows.concat(@lines.map(&:row))
            rows
          end
        end
      RUBY
    end

    it "proposes no name where the rest of the name is a phrase, not a noun" do
      expect_offense(<<~RUBY)
        class Post
          def self.find_by_slug(slug) = where(slug:).first
                   ^^^^^^^^^^^^ A builder is named for what it returns, not `find_by_slug`: name it for the object it answers.
          def load_from(path) = File.read(path)
              ^^^^^^^^^ A builder is named for what it returns, not `load_from`: name it for the object it answers.
        end
      RUBY
    end

    it "leaves a method that acts on the way to its verb" do
      expect_no_offenses(<<~RUBY)
        class Signup
          def create_user(attrs) = User.create!(attrs)
          def find_or_create_tag(name) = Tag.find_or_create_by(name:)
          def build_index = client.indices.create(index: "users")
          def load_user
            @user = User.find(params[:id])
          end
          def build_profile = self.profile = Profile.new
          def fetch_rows(row) = @rows << row
          def make_welcome(user) = UserMailer.welcome(user).deliver_later
          def load_tasks = Dir["tasks/*.rake"].each { load(it) }
          def load_plugins
            require "shop/plugins"
            Plugins.all
          end
          def prepare_report(lines)
            lines.sort!
            lines.join
          end
          def build_nothing
          end
          def build_blank
            nil
          end
          def build_log = puts("built")
          def build_totals = @lines.each { |line| line.total }
          def build_count
            @@count = 1
          end
          def build_seen
            $seen = true
          end
          def build_name=(value)
            value
          end
          def create_command_and_execute(args) = command(args).tap { run(it) }
          def find_and_cache(key) = key
          def create_or_update_params = params.require(:site).permit(:name)
          def load_path = @load_path ||= LoadPath.new(paths)
          def create_abstract_method(name) = define_method(name) { fail NotImplementedError }
          def create_notice(notice)
            Bullet.collector.add(notice) if notice
          end
          def prepare_page
            command("Page.enable")
            command("Runtime.enable")
            @page
          end
        end
      RUBY
    end

    # places-manager's `before_validation :create_first_data_set`; rack-mini-profiler's alias chain on Plucky::Query.
    it "leaves a callback the framework runs, and a method an alias chain keeps the library's name for" do
      expect_no_offenses(<<~RUBY)
        class Service < ApplicationRecord
          before_validation :create_first_data_set, on: :create
          def create_first_data_set = data_sets.first || 1
        end
        class Plucky::Query
          alias_method :find_one_without_profiling, :find_one
          alias find_each_without_profiling find_each
          def find_one(*args) = profiled(args)
          def find_each(*args) = profiled(args)
        end
      RUBY
    end

    it "judges a builder that guards, builds a local and names a callback it is not" do
      expect_offense(<<~RUBY)
        class Report
          after_save :publish
          helper_method :build_title
          def build_title(name)
              ^^^^^^^^^^^ A builder is named for what it returns: `title`, not `build_title`.
            raise ArgumentError, "no name" unless name
            parts = []
            parts << name
            parts.join
          end
        end
      RUBY
    end

    it "judges a call to a loading or output word made on an object, not on Kernel, as a value" do
      expect_offense(<<~RUBY)
        class Settings
          def load_config(text) = YAML.load(text)
              ^^^^^^^^^^^ A builder is named for what it returns: `config`, not `load_config`.
        end
      RUBY
    end

    it "frees a noun by its own kind: a class method beside an instance one, a top-level method beside none" do
      expect_offense(<<~RUBY)
        class Grid
          def point = 1
          def self.make_point = new
                   ^^^^^^^^^^ A builder is named for what it returns: `point`, not `make_point`.
          def self.cell = 2
          def self.make_cell = new
        end
        def build_report = 1
            ^^^^^^^^^^^^ A builder is named for what it returns: `report`, not `build_report`.
        def summary = 1
        def build_summary = 1
      RUBY
    end

    it "leaves the work behind a noun the class or its ancestors already answer" do
      expect_no_offenses(<<~RUBY)
        class Shop
          attr_reader :config
          def summary = @summary ||= build_summary
          def build_summary = "\#{@lines.size} lines"
          def load_config = YAML.load_file("shop.yml")
        end
      RUBY
    end

    it "leaves predicates, bang methods and setters to their verbs" do
      expect_no_offenses(<<~RUBY)
        class Index
          def find_user?(id) = @users.key?(id)
          def build_index! = @index.rebuild
          def load_path=(path)
            @load_path = path
          end
        end
      RUBY
    end

    context "when it is off" do
      let(:cop_config) { RuboCop::ConfigLoader.default_configuration.for_cop("Kata/BuilderNoun") }

      it "keeps the shipped reading, which leaves the other verbs alone" do
        expect_offense(<<~RUBY)
          def build_summary = 1
          def get_total = 2
              ^^^^^^^^^ A builder is named for what it returns: `total`, not `get_total`.
        RUBY
      end
    end
  end
end
