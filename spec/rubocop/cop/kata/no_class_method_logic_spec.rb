# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::NoClassMethodLogic, :config) do
  let(:ruby_version) { 3.4 }

  let(:cop_config) { { "AllowedNames" => %w[build included] } }

  it "flags class methods that carry logic" do
    expect_offense(<<~RUBY)
      def self.total_for(user)
               ^^^^^^^^^ `total_for` puts logic on the class; classes construct, instances work.
        user.total
      end
    RUBY
  end

  it "flags class methods opened with class << self" do
    expect_offense(<<~RUBY)
      class Ledger
        class << self
          def total_for(user)
              ^^^^^^^^^ `total_for` puts logic on the class; classes construct, instances work.
            user.total
          end

          def build
            new
          end
        end
      end
    RUBY
  end

  it "leaves instance methods alone, in a class or in a block" do
    expect_no_offenses(<<~RUBY)
      class Ledger
        def total_for(user)
          user.total
        end
      end
      class << self
        Class.new do
          def total_for(user)
            user.total
          end
        end
      end
    RUBY
  end

  it "allows constructors and hooks" do
    expect_no_offenses(<<~RUBY)
      def self.build
        new
      end
      def self.from_json(json)
        new(json)
      end
      def self.included(base)
        base.extend(self)
      end
    RUBY
  end

  it "flags a module of functions" do
    expect_offense(<<~RUBY)
      module Pricing
        module_function
        ^^^^^^^^^^^^^^^ `module_function` turns the module into a bag of functions; give the logic an object that holds its data.

        def total(lines) = lines.sum(&:price)
      end
      module Tax
        extend self
        ^^^^^^^^^^^ `extend self` turns the module into a bag of functions; give the logic an object that holds its data.
      end
      module Rates
        module_function :lookup
        ^^^^^^^^^^^^^^^^^^^^^^^ `module_function` turns the module into a bag of functions; give the logic an object that holds its data.
      end
    RUBY
  end

  it "leaves extending another module, and code outside a module, alone" do
    expect_no_offenses(<<~RUBY)
      module Pricing
        extend Forwardable
        extend(self, Other)
        class Line
          extend self
        end
        Class.new { extend self }
      end
      extend self
      Pricing.module_function
    RUBY
  end

  it "reads a class method whose result is a new instance of its class as a constructor" do
    expect_no_offenses(<<~RUBY)
      class Rubric
        def self.build_from_legacy(legacy) = new(legacy.title)
        def self.create(title) = self.new(title.strip)
        def self.restore(row)
          title = row.fetch(:title)
          Rubric.new(title)
        end
      end
    RUBY
  end

  it "still flags a class method that builds some other class" do
    expect_offense(<<~RUBY)
      class Rubric
        def self.export(rubric) = Sheet.new(rubric)
                 ^^^^^^ `export` puts logic on the class; classes construct, instances work.
        def self.copy(rubric) = rubric.new
                 ^^^^ `copy` puts logic on the class; classes construct, instances work.
        def self.reset = clear_all
                 ^^^^^ `reset` puts logic on the class; classes construct, instances work.
      end
      module Rubrics
        def self.make(title) = Rubrics.new(title)
                 ^^^^ `make` puts logic on the class; classes construct, instances work.
      end
    RUBY
  end

  context "with the shipped defaults" do
    let(:cop_config) { RuboCop::ConfigLoader.default_configuration.for_cop("Kata/NoClassMethodLogic") }

    it "allows the serialization protocols a framework calls on the class" do
      expect_no_offenses(<<~RUBY)
        class Money
          def self.load(text) = new(text)
          def self.dump(money) = money.to_s
          def self._load(text) = new(text)
          def self.json_create(object) = new(object["cents"])
          def self.[](*parts) = new(*parts)
        end
      RUBY
    end

    it "allows the protocol methods Ruby calls on a class by name" do
      expect_no_offenses(<<~RUBY)
        class Rubric
          def self.name = "Rubric"
          def self.to_s = name
          def self.inspect = name
          def self.===(other) = other.is_a?(Hash)
          def self.respond_to_missing?(name, all) = name.start_with?("of_") || super
          def self.method_missing(name, *) = name.start_with?("of_") ? new : super
          def self.to_proc = method(:new).to_proc
        end
      RUBY
    end

    it "still flags a query on the class" do
      expect_offense(<<~RUBY)
        class Money
          def self.active = all.select(&:active?)
                   ^^^^^^ `active` puts logic on the class; classes construct, instances work.
        end
      RUBY
    end
  end

  it "asks for a constant when a class method only returns a literal" do
    expect_offense(<<~RUBY)
      class Wizard
        def self.steps = %i[name email confirm]
                 ^^^^^ `steps` only returns a literal; make it a constant.
        def self.limit = LIMIT
                 ^^^^^ `limit` puts logic on the class; classes construct, instances work.
      end
    RUBY
  end

  # cancancan: `AbstractAdapter.for_class?(_member_class) = false`, which each adapter overrides with logic.
  it "asks for a constant only for a method that takes nothing and no subclass redefines" do
    expect_offense(<<~RUBY)
      class Adapter
        def self.for_class?(_model) = false
                 ^^^^^^^^^^ `for_class?` puts logic on the class; classes construct, instances work.
        def self.available? = true
                 ^^^^^^^^^^ `available?` puts logic on the class; classes construct, instances work.
        def self.steps = %i[a b]
                 ^^^^^ `steps` only returns a literal; make it a constant.
      end
      class RecordAdapter < Adapter
        def self.available? = !ActiveRecord.nil?
                 ^^^^^^^^^^ `available?` puts logic on the class; classes construct, instances work.
        def available? = false
        def LIMITS.steps = []
                   ^^^^^ `steps` only returns a literal; make it a constant.
      end
    RUBY
  end

  # acts-as-taggable-on: `extend ActsAsTaggableOn::Taggable` gives every model `taggable?` (false), and
  # `taggable_on` overrides it with `def self.taggable? = true` in `class_eval` on the class it tags (R6B6-K4).
  it "leaves a class-level override of the default a module the class extends answers" do
    expect_no_offenses(<<~RUBY)
      module Taggable
        def taggable? = false

        def acts_as_taggable
          class_eval do
            def self.taggable? = true
          end
        end

        def acts_as_tagger
          def self.tagger? = true
        end

        def tagger? = false
      end

      module Defaults
        def label = "item"
      end

      module Searchable
        module ClassMethods
          def fields = []
        end
      end

      class Post
        extend Defaults
        include Searchable

        def self.label = "post"
        def self.fields = %i[title body]
      end

      class Article < Post
        def self.label = "article"
      end

      class Note
        extend Taggable

        class << self
          def taggable? = true
        end
      end
    RUBY
  end

  # ffaker's `module ArrayUtils; extend RandomUtils; def self.rand(array)`: a module of functions, not a class.
  it "still asks for a constant where no extended module answers the name, or a module overrides one" do
    expect_offense(<<~RUBY)
      module Taggable
        def acts_as_taggable
          class_eval do
            def self.taggable? = true
                     ^^^^^^^^^ `taggable?` only returns a literal; make it a constant.
          end
        end
      end

      module Defaults
        def label = "item"
        def caption = "item"
      end

      class Post
        include Defaults

        def self.caption = "post"
                 ^^^^^^^ `caption` only returns a literal; make it a constant.

        def refresh
          self.class.class_eval { def self.stale? = true }
                                           ^^^^^^ `stale?` only returns a literal; make it a constant.
        end

        def stale? = false
      end

      module Shuffling
        extend Defaults

        def self.label = "shuffled"
                 ^^^^^ `label` only returns a literal; make it a constant.
      end
    RUBY
  end

  # support: twenty `Support::Requests::*Request` classes answer `self.label`, which a section sends to the class it
  # holds; a constant read through `klass::LABEL` would replace that message with shared state.
  context "with the project's other classes" do
    include ProjectFiles

    let(:setting) { { "Kata/NoClassMethodLogic" => { "OwnedPaths" => ["app/**/*.rb"] } } }
    let(:files) do
      {
        "app/models/analytics_request.rb" => "class AnalyticsRequest < Request\n  def self.label = \"A\"\nend\n",
        "app/models/general_request.rb" => "class GeneralRequest < Request\n  def self.label = \"B\"\nend\n",
        "app/models/section.rb" => "class Section\n  def name = @kind.label\nend\n",
        "app/models/wizard.rb" => "class Wizard\n  def self.steps = %i[name email]\nend\n"
      }
    end

    it "asks for no constant where another class answers the same class-level message" do
      shared = "`label` puts logic on the class; classes construct, instances work."
      alone = "`steps` only returns a literal; make it a constant."
      found = files.keys.map { |path| project_offenses(files, path).map(&:message) }
      expect(found).to(eq([[shared], [shared], [], [alone]]))
    end
  end

  # dry-monads: SuperDiff asks each registered tree class `applies_to?`; `Maybe.to_proc` serves `map(&Maybe)`.
  context "with a foreign framework's hooks" do
    include ProjectFiles

    let(:setting) { { "Kata/NoClassMethodLogic" => { "OwnedPaths" => ["lib/**/*.rb"], "AllowedNames" => [] } } }
    let(:trees) do
      <<~RUBY
        module Trees
          class Tuple < ::SuperDiff::Trees::Array
            def self.applies_to?(value) = value.frozen?
          end
          class Dict < ::SuperDiff::Trees::Hash
            def self.applies_to?(value) = value.frozen?
          end
          class Pair < Tuple
            def self.applies_to?(value) = super && value.size == 2
          end
          class Lone < ::SuperDiff::Trees::Object
            def self.inspectable?(value) = super(value) && value.frozen?
            def self.printable?(value) = super && value.frozen?
            def self.tally(rows) = rows.size
            class << self
              def wrap(value) = super
            end
          end
          class Record < ::ActiveRecord::Base
            def self.search(query) = where(query)
            def self.export(rows) = rows
          end
          class User < Record
            def self.search(query) = super.limit(1)
            def self.export(rows) = rows
          end
          class Plain
            def self.listed(value) = super
            def self.shown(value) = value
          end
          class Other
            def self.shown(value) = value
          end
          module Mixin
            include ::SuperDiff::Hooks
            def self.hooked(value) = super
          end
          class Request
            include ::ActiveModel::Model
          end
          class Analytics < Request
            def self.described = "a"
          end
          class General < Request
            def self.described = "b"
          end
        end
      RUBY
    end
    let(:caller) { "module Trees\n  class Finder\n    def find(text) = User.search(text).export(text)\n  end\nend\n" }

    it "leaves a hook that overrides a foreign ancestor's, or that classes under one answer unsent" do
      found = project_offenses({ "lib/trees.rb" => trees, "lib/finder.rb" => caller }, "lib/trees.rb")
      expect(found.map(&:line)).to(eq([14, 16, 20, 21, 24, 25, 28, 29, 32, 36, 42, 45]))
    end

    it "reads the superclass a class is defined with where another file reopens it" do
      reopened = "module Trees\n  class Lone\n    def self.shown?(value) = super\n  end\nend\n"
      files = { "lib/trees.rb" => trees, "lib/trees/lone.rb" => reopened, "lib/finder.rb" => caller }
      expect(project_offenses(files, "lib/trees/lone.rb")).to(be_empty)
    end
  end
end
