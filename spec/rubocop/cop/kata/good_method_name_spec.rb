# frozen_string_literal: true

require "tmpdir"

RSpec.describe(RuboCop::Cop::Kata::GoodMethodName, :config) do
  let(:ruby_version) { 3.4 }
  let(:defaults) { YAML.load_file("config/default.yml", aliases: true).fetch("Kata/GoodMethodName") }
  let(:cop_config) { defaults.merge("Terms" => [], "AllowedNames" => []) }

  def offense(name, count = 3, max = 2)
    "`#{name}` strings #{count} words together, past the #{max} a name carries: a concept is missing, or the " \
      "method belongs on the object the words describe. Say it in fewer, move it, give a role a " \
      "`Prefixes`/`Suffixes` word — or, if `#{name}` is one domain concept here, add it to `Terms`."
  end

  it "ignores operator methods — Ruby dictates their names" do
    expect_no_offenses(<<~RUBY)
      def [](key)
      end
      def []=(key, value)
      end
      def ==(other)
      end
      def <=>(other)
      end
      def <<(item)
      end
    RUBY
  end

  it "judges a hook name by its words, not the underscores Ruby puts in front" do
    expect_no_offenses(<<~RUBY)
      def _fork
      end
      def _dump(level)
      end
      def __send
      end
    RUBY
  end

  it "still counts the words behind the underscores" do
    expect_offense(<<~RUBY)
      def _merge_cached_rows
          ^^^^^^^^^^^^^^^^^^ #{offense("_merge_cached_rows")}
      end
    RUBY
  end

  it "allows single-word names" do
    expect_no_offenses(<<~RUBY)
      def coverage
      end
      def survivors?
      end
      def kill!
      end
      def source=(value)
      end
    RUBY
  end

  it "allows role prefixes" do
    expect_no_offenses(<<~RUBY)
      def after_fork
      end
      def before_exit
      end
      def around_mutant
      end
      def on_def
      end
      def each_group
      end
      def for_diff
      end
      def from_message
      end
      def to_h
      end
      def by_kill_likelihood
      end
      def with_timeout
      end
      def test_invoke_private
      end
      def fake_adapter
      end
    RUBY
  end

  it "allows role suffixes" do
    expect_no_offenses(<<~RUBY)
      def file_of
      end
      def tests_for
      end
      def points_at
      end
    RUBY
  end

  it "allows two words, which are often one concept's honest name" do
    expect_no_offenses(<<~RUBY)
      def build_adapter
      end
      def matching_ids
      end
      def harness_critical?
      end
      def source_root=(value)
      end
    RUBY
  end

  it "flags three words, where a concept or a method home is missing" do
    %w[assemble_monthly_report drive_worker_pool apply_exclude_globs].each do |name|
      expect_offense(<<~RUBY, name: name, message: offense(name))
        def %{name}
            ^{name} %{message}
        end
      RUBY
    end
  end

  it "flags three-word predicates, bangs, and setters, role prefix or not" do
    expect_offense(<<~RUBY)
      def harness_critical_zone?
          ^^^^^^^^^^^^^^^^^^^^^^ #{offense("harness_critical_zone?")}
      end
      def install_enum_guard!
          ^^^^^^^^^^^^^^^^^^^ #{offense("install_enum_guard!")}
      end
      def source_tree_root=(value)
          ^^^^^^^^^^^^^^^^^ #{offense("source_tree_root=")}
      end
      def self.fork_pool_worker
               ^^^^^^^^^^^^^^^^ #{offense("fork_pool_worker")}
      end
    RUBY
  end

  it "does not count role words" do
    expect_no_offenses(<<~RUBY)
      def to_line_items
      end
      def line_item_count
      end
      def source_root_path=(value)
      end
    RUBY
  end

  it "flags a segment the pattern rejects" do
    expect_offense(<<~RUBY)
      def supercalifragilistic
          ^^^^^^^^^^^^^^^^^^^^ `supercalifragilistic`: the segment `supercalifragilistic` does not match `Pattern`; a segment is one lowercase word.
      end
    RUBY
  end

  context "with MaxWords 1, for a team that wants one word" do
    let(:cop_config) { defaults.merge("Terms" => [], "AllowedNames" => [], "MaxWords" => 1) }

    it "flags two words" do
      expect_offense(<<~RUBY)
        def build_adapter
            ^^^^^^^^^^^^^ #{offense("build_adapter", 2, 1)}
        end
        def to_line_items
            ^^^^^^^^^^^^^ #{offense("to_line_items", 2, 1)}
        end
      RUBY
    end

    it "still allows a word with its roles" do
      expect_no_offenses(<<~RUBY)
        def after_fork
        end
        def file_of
        end
      RUBY
    end
  end

  context "with domain terms declared" do
    let(:cop_config) { defaults.merge("Terms" => %w[date_of_birth billing_cycle_day], "AllowedNames" => []) }

    it "allows them" do
      expect_no_offenses(<<~RUBY)
        def date_of_birth
        end
        def billing_cycle_day
        end
      RUBY
    end
  end

  context "with the shipped defaults" do
    let(:cop_config) { defaults }

    it "exempts the names Ruby and Rails resolve by contract" do
      expect_no_offenses(<<~RUBY)
        def method_missing(name, *args)
        end
        def respond_to_missing?(name, all)
        end
        def marshal_dump
        end
        def deep_dup
        end
        def table_name
        end
      RUBY
    end

    it "exempts the names Rails, Pundit, Ransack, Devise and Phlex call by contract" do
      expect_no_offenses(<<~RUBY)
        def validate_each(record, attribute, value)
        end
        def self.ransackable_attributes(auth = nil)
        end
        def policy_class
        end
        def view_template
        end
      RUBY
    end
  end

  it "leaves a Minitest name to read as the sentence it is" do
    expect_no_offenses(<<~RUBY)
      class InvoiceTest < Minitest::Test
        def test_totals_the_billable_lines
        end
      end
      class Billing < ActiveSupport::TestCase
        def test_refunds_a_voided_invoice
        end
      end
    RUBY
  end

  it "prices a test_ name outside a test class" do
    expect_offense(<<~RUBY)
      class Adapter < Base
        def test_reopen_stale_connection
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense("test_reopen_stale_connection")}
        end
      end
      def test_reopen_stale_connection
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense("test_reopen_stale_connection")}
      end
      class Probe
        def test_reopen_stale_connection
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense("test_reopen_stale_connection")}
        end
      end
    RUBY
  end

  it "flags a name chaining actions with a conjunction" do
    expect_offense(<<~RUBY)
      def validate_and_save
          ^^^^^^^^^^^^^^^^^ `validate_and_save` chains actions with `and`; each action wants its own method.
      end
      def find_or_create
          ^^^^^^^^^^^^^^ `find_or_create` chains actions with `or`; each action wants its own method.
      end
    RUBY
  end

  context "with the patterns a dispatcher dictates" do
    let(:cop_config) { defaults.merge("Terms" => [], "AllowedNames" => [], "AllowedPatterns" => ["_sql\\z"]) }

    it "leaves a name the pattern matches, and prices the rest" do
      expect_offense(<<~RUBY)
        def select_limit_sql; end
        def customer_billing_address; end
            ^^^^^^^^^^^^^^^^^^^^^^^^ #{offense("customer_billing_address")}
      RUBY
    end
  end

  it "ships Prism's listener names as a contract" do
    expect(defaults.fetch("AllowedPatterns").map { Regexp.new(it) }.map { "on_call_node_enter".match?(it) })
      .to(eq([true]))
  end

  context "with the raw escape hatch" do
    let(:cop_config) { defaults.merge("Terms" => [], "AllowedNames" => %w[build_pool_adapter]) }

    it "allows the listed name" do
      expect_no_offenses(<<~RUBY)
        def build_pool_adapter
        end
      RUBY
    end
  end

  it "allows a name that is a bare role word" do
    expect_no_offenses(<<~RUBY)
      def after
      end
      def count
      end
    RUBY
  end

  it "prices the names attr macros, define_method and alias mint, not only def" do
    expect_offense(<<~RUBY)
      attr_reader :name, :user_home_page
                         ^^^^^^^^^^^^^^^ #{offense("user_home_page")}
      attr_accessor "billing_cycle_day"
                    ^^^^^^^^^^^^^^^^^^^ #{offense("billing_cycle_day")}
      attr_writer :user_home_page
                  ^^^^^^^^^^^^^^^ #{offense("user_home_page")}
      define_method(:user_home_page) { "x" }
                    ^^^^^^^^^^^^^^^ #{offense("user_home_page")}
      alias_method :user_home_page, :name
                   ^^^^^^^^^^^^^^^ #{offense("user_home_page")}
      alias user_home_page name
            ^^^^^^^^^^^^^^ #{offense("user_home_page")}
    RUBY
  end

  it "judges only the new name of an alias, and leaves other calls alone" do
    expect_no_offenses(<<~RUBY)
      alias_method :name, :user_home_page
      alias name user_home_page
      define_method(name) { "x" }
      record.attr_reader(:user_home_page)
      validates :user_home_page, presence: true
      alias $new $old
    RUBY
  end

  it "reads the macros on self too" do
    expect_offense(<<~RUBY)
      self.define_method(:user_home_page) { "x" }
                         ^^^^^^^^^^^^^^^ #{offense("user_home_page")}
    RUBY
  end

  context "with joint words and the atomic vocabulary" do
    let(:ruby_version) { 3.4 }
    let(:cop_config) do
      { "MaxWords" => 2, "Prefixes" => %w[on], "AllowedNames" => %w[compare_and_set get_and_set] }
    end

    it "reads a joint only between two words, after the role prefix" do
      expect_offense(<<~RUBY)
        class Cell
          def then(value) = value
          def or(other) = other
          def on_and(node) = node
          def compare_and_set(old, new) = [old, new]
          def save_and_close = nil
              ^^^^^^^^^^^^^^ `save_and_close` chains actions with `and`; each action wants its own method.
        end
      RUBY
    end
  end

  context "with the project's other files" do
    include TabledCop

    let(:root) { Dir.mktmpdir("kata-names") }
    let(:cop) do
      shipped = { "Kata/GoodMethodName" => { "OwnedPaths" => ["lib/**/*.rb"], "MaxWords" => 2 } }
      described_class.new(RuboCop::Config.new(shipped, File.join(root, ".rubocop.yml")))
    end

    before do
      FileUtils.mkdir_p(File.join(root, "lib"))
      base = "module Shelf\n  class Fetcher\n    def check_required_files = nil\n    " \
        "def self.fetch_lock_files = nil\n    def flip(owner) = owner.clear_action_methods!\n  end\nend\n"
      File.write(File.join(root, "lib", "fetcher.rb"), base)
      File.write(File.join(root, "lib", "npm.rb"), "module Shelf\n  class Npm < Fetcher\n  end\nend\n")
    end

    after { FileUtils.rm_rf(root) }

    it "reports a name once, where it was chosen, not in each override" do
      source = "module Shelf\n  class Npm\n    def check_required_files = 1\n    " \
        "def fetch_lock_files = 2\n  end\nend\n"
      expect(offenses(source).map(&:line)).to(eq([4]))
    end

    # kimera's runtime_spec: the stand-in answers the message lib/ sends to a
    # Rails controller.
    it "leaves a stand-in for a message the project sends but never defines to the caller's name" do
      source = "controller = Class.new { def self.clear_action_methods! = 1 }\n" \
        "define_method(:clear_action_methods!) { 1 }\ndef assemble_monthly_report = 1\n"
      expect(offenses(source).map(&:line)).to(eq([3]))
    end
  end

  # kimera's TestExit and unparser emitters: the ancestor chose the name.
  it "leaves a method that calls super to its ancestor's name" do
    expect_no_offenses(<<~RUBY)
      module Example
        def with_around_example_hooks
          super
        rescue SystemExit => error
          error
        end

        def visit_begin_node(node) = endpoint(node) { super }

        def self.clear_reflections_cache(*) = super(*)
      end
    RUBY
  end

  it "still prices a method whose super belongs to a method nested inside it" do
    expect_offense(<<~RUBY)
      def define_monthly_report
          ^^^^^^^^^^^^^^^^^^^^^ #{offense("define_monthly_report")}
        Class.new { def total = super }
      end
    RUBY
  end
end
