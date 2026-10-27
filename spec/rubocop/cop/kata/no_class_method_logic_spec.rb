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
end
