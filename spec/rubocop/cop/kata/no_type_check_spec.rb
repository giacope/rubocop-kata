# frozen_string_literal: true

require "tmpdir"

RSpec.describe(RuboCop::Cop::Kata::NoTypeCheck, :config) do
  let(:ruby_version) { 3.4 }

  let(:cop_config) { { "AllowedMethods" => %w[== coerce], "OwnedPaths" => [], "Dependencies" => [] } }

  it "flags asking an object whether it is one of the project's own types" do
    expect_offense(<<~RUBY)
      class Card
      end
      module Billing
        class Invoice
          def settle = nil
        end
      end
      def render(value)
        return value.to_s if value.is_a?(Card)
                                   ^^^^^ `is_a?` asks an object what it is; tell it what to do, and let polymorphism choose.
        return value.settle if value.respond_to?(:settle)
                                     ^^^^^^^^^^^ `respond_to?` asks an object what it is; tell it what to do, and let polymorphism choose.
        return value if value.kind_of?(Billing::Invoice) || value.instance_of?(::Card)
                              ^^^^^^^^ `kind_of?` asks an object what it is; tell it what to do, and let polymorphism choose.
                                                                  ^^^^^^^^^^^^ `instance_of?` asks an object what it is; tell it what to do, and let polymorphism choose.
      end
    RUBY
  end

  it "leaves a check against a type another library owns, which is a boundary" do
    expect_no_offenses(<<~RUBY)
      def render(value)
        return value.to_s if value.is_a?(Symbol)
        return value if value.kind_of?(String) || value.instance_of?(RuboCop::AST::Node)
        value.respond_to?(:upcase) ? value.upcase : value
      end
    RUBY
  end

  it "leaves a class Ruby defines, even where the project reopens it or reuses its name in a namespace" do
    expect_no_offenses(<<~RUBY)
      class String
        def shout = upcase
      end
      module Types
        class Hash; end
      end
      def render(value) = value.is_a?(String) || value.is_a?(::Hash)
    RUBY
  end

  # Kimera's `Shift::Doubt =\n  Class.new(Suspect) do` went unflagged.
  it "counts a constant the file assigns a new class, module, Struct or Data to as the project's own" do
    expect_offense(<<~RUBY)
      Point = Struct.new(:x)
      Billing::Draft =
        Data.define(:id) do
          def ok? = true
        end
      Failure = Class.new(StandardError)
      ::Mixin = Module.new
      Plain = Object.new
      Limit = 3
      Built = build
      def point?(value) = value.is_a?(Point)
                                ^^^^^ `is_a?` asks an object what it is; tell it what to do, and let polymorphism choose.
      def draft?(value) = value.is_a?(Billing::Draft)
                                ^^^^^ `is_a?` asks an object what it is; tell it what to do, and let polymorphism choose.
      def failure?(value) = value.is_a?(Failure)
                                  ^^^^^ `is_a?` asks an object what it is; tell it what to do, and let polymorphism choose.
      def mixin?(value) = value.is_a?(Mixin)
                                ^^^^^ `is_a?` asks an object what it is; tell it what to do, and let polymorphism choose.
      def other(value) = value.is_a?(Plain) || value.is_a?(Limit) || value.is_a?(Built)
    RUBY
  end

  it "counts each name of a compact definition as the project's own" do
    expect_offense(<<~RUBY)
      class Billing::Amount
        def same?(value) = value.is_a?(Billing::Amount)
                                 ^^^^^ `is_a?` asks an object what it is; tell it what to do, and let polymorphism choose.
      end
    RUBY
  end

  it "leaves a library's class that shares its last name with one of the project's own" do
    expect_no_offenses(<<~RUBY)
      class AuthenticationError < StandardError; end
      def retry?(error) = !error.is_a?(Koala::Facebook::AuthenticationError)
    RUBY
  end

  it "reads a constant under a namespace it cannot name without asking Ruby for it" do
    expect_no_offenses("def render(value) = value.is_a?(value.class::Missing)\n")
  end

  it "flags the project's own type that shares a name with one Ruby defines, written with its namespace" do
    expect_offense(<<~RUBY)
      module Types
        class String; end
      end
      def render(value) = value.is_a?(Types::String)
                                ^^^^^ `is_a?` asks an object what it is; tell it what to do, and let polymorphism choose.
    RUBY
  end

  it "leaves the conversion and iteration protocols, even where the project defines them" do
    expect_no_offenses(<<~RUBY)
      class Card
        def to_h = {}
        def each = nil
        def call = nil
      end
      def render(value) = [value.respond_to?(:to_h), value.respond_to?(:each), value.respond_to?(:call)]
    RUBY
  end

  it "flags a check on an own type outside any method" do
    expect_offense(<<~RUBY)
      class Card; end
      HANDLER = value.is_a?(Card) ? value : proc { value }
                      ^^^^^ `is_a?` asks an object what it is; tell it what to do, and let polymorphism choose.
    RUBY
  end

  it "allows the protocols that must check what they were handed" do
    expect_no_offenses(<<~RUBY)
      class Money; end
      def ==(other) = other.is_a?(Money) && cents == other.cents
      def self.coerce(other) = other.respond_to?(:to_money) ? other.to_money : other
    RUBY
  end

  # dry-monads' `matcher :be_none do match { |actual| actual.is_a?(None) } end`: RSpec hands the block any object.
  it "allows a matcher's match block, whose contract is to check what it was handed" do
    expect_no_offenses(<<~RUBY)
      class Tuple; end
      RSpec::Matchers.define :be_tuple do
        match { |actual| actual.is_a?(Tuple) }
        match_when_negated { |actual| !actual.is_a?(Tuple) }
      end
      matcher :be_pair do
        description { "a pair" }
        match { |actual| actual.is_a?(Tuple) }
      end
    RUBY
  end

  it "still flags a check elsewhere in a matcher, and a match block outside one" do
    expect_offense(<<~RUBY)
      class Tuple; end
      RSpec::Matchers.define :be_tuple do
        failure_message { |actual| actual.is_a?(Tuple) ? "a" : "b" }
                                          ^^^^^ `is_a?` asks an object what it is; tell it what to do, and let polymorphism choose.
      end
      Shelf::Matchers.define :be_tuple do
        match { |actual| actual.is_a?(Tuple) }
                                ^^^^^ `is_a?` asks an object what it is; tell it what to do, and let polymorphism choose.
      end
      match { |actual| actual.is_a?(Tuple) }
                              ^^^^^ `is_a?` asks an object what it is; tell it what to do, and let polymorphism choose.
    RUBY
  end

  # dry-monads' SuperDiff extension: SuperDiff asks each registered tree class `applies_to?` about any value.
  it "allows a class-level hook that classes under a foreign superclass answer, and flags an instance method" do
    expect_offense(<<~RUBY)
      class Tuple; end
      class TupleTree < ::SuperDiff::Trees::Array
        def self.applies_to?(value) = value.is_a?(Tuple)
      end
      class DictTree < ::SuperDiff::Trees::Hash
        def self.applies_to?(value) = value.is_a?(Tuple)
        def applies_to?(value) = value.is_a?(Tuple)
                                       ^^^^^ `is_a?` asks an object what it is; tell it what to do, and let polymorphism choose.
      end
    RUBY
  end

  it "leaves other predicates, and a probe it cannot name, alone" do
    expect_no_offenses(<<~RUBY)
      class Money; end
      value.nil?
      value.empty?
      Symbol === value
      value.class == String
      value.is_a?(kind)
      value.respond_to?(name)
      value.is_a?
    RUBY
  end

  it "judges a project's own top-level type whatever RuboCop itself has loaded" do
    expect_offense(<<~RUBY)
      class Parser; end
      module AST; end
      class Rainbow; end
      def render(input)
        input.is_a?(Parser) || input.is_a?(AST) || input.is_a?(Rainbow)
              ^^^^^ `is_a?` asks an object what it is; tell it what to do, and let polymorphism choose.
                                     ^^^^^ `is_a?` asks an object what it is; tell it what to do, and let polymorphism choose.
                                                         ^^^^^ `is_a?` asks an object what it is; tell it what to do, and let polymorphism choose.
      end
    RUBY
  end

  it "reads every spelling of a type ladder over the project's own classes" do
    expect_offense(<<~RUBY)
      module Shapes
        class Circle; end
        class Square; end

        def self.area(shape)
          case shape
          ^^^^ `case … when` asks an object what it is; tell it what to do, and let polymorphism choose.
          when Circle then 1
          when Square then 2
          end
        end

        def self.side(shape)
          case shape
          ^^^^ `case … in` asks an object what it is; tell it what to do, and let polymorphism choose.
          in Square(size:) then size
          in Integer then shape
          end
        end

        def self.round?(shape) = Circle === shape || shape.class == Circle || Square == shape.class
                                        ^^^ `===` asks an object what it is; tell it what to do, and let polymorphism choose.
                                                                 ^^ `class ==` asks an object what it is; tell it what to do, and let polymorphism choose.
                                                                                     ^^ `class ==` asks an object what it is; tell it what to do, and let polymorphism choose.

        def self.named?(shape) = shape.class.name == "Circle" || shape.class.name != "Tag"
                                                  ^^ `class.name ==` asks an object what it is; tell it what to do, and let polymorphism choose.
      end
    RUBY
  end

  it "leaves a ladder over foreign classes and a subjectless case alone" do
    expect_no_offenses(<<~RUBY)
      class Circle; end
      def kind(value)
        case value
        when String, Integer then :scalar
        end
      end
      def pick(flag)
        case
        when flag then Circle
        end
      end
      def named?(value) = value.class.name == "String" || value.name == "Circle"
      module Shelf
        def self.open = nil
      end
      def remote?(value) = case value
                           in Shelf::Remote then true
                           in Integer then false
                           end
      def ==(other) = other.class == Circle
    RUBY
  end

  it "resolves a name through the lexical nesting, as Ruby does" do
    expect_offense(<<~RUBY)
      module Shelf
        class Base; end

        class Item
          def same?(other) = other.is_a?(Base)
                                   ^^^^^ `is_a?` asks an object what it is; tell it what to do, and let polymorphism choose.
        end
      end
      module ActiveJob
        module QueueAdapters
          class ShelfAdapter; end
        end
      end
      module Rack
        class Shelf::Request; end
      end
      def boundary(job, env) = job.is_a?(ActiveJob::Base) || env.is_a?(Rack::Request) || job.is_a?(Base)
      def rack?(env) = env.is_a?(Rack) || env.is_a?(ActiveJob)
      module Shelf
        def self.top?(item) = item.is_a?(::Base)
      end
    RUBY
  end

  it "judges a project's own class under a core namespace, but not a reopened core class" do
    expect_offense(<<~RUBY)
      module Gem
        class Source
          def update = nil
        end

        class SourceList
          def add(other) = other.is_a?(Gem::Source) || other.is_a?(Source)
                                 ^^^^^ `is_a?` asks an object what it is; tell it what to do, and let polymorphism choose.
                                                             ^^^^^ `is_a?` asks an object what it is; tell it what to do, and let polymorphism choose.
        end
      end
      class String
        def shout = upcase
      end
      def text?(value) = value.is_a?(String)
    RUBY
  end

  context "with the shipped protocol inventories" do
    let(:cop_config) do
      { "AllowedMethods" => [], "OwnedPaths" => [], "Protocols" => %w[ruby rails], "Dependencies" => [] }
    end

    it "reads a probe of a name Ruby's or Rails' public classes answer as a protocol" do
      expect_offense(<<~RUBY)
        class Ledger
          def warn(text) = text
          def lease_connection = nil
          def defined_enums = {}
          def settle = nil
        end
        def log(logger) = logger.respond_to?(:warn) && logger.respond_to?(:lease_connection)
        def pay(bill) = bill.respond_to?(:settle) || bill.respond_to?(:defined_enums)
                             ^^^^^^^^^^^ `respond_to?` asks an object what it is; tell it what to do, and let polymorphism choose.
      RUBY
    end
  end

  # In the rubocop gem, `node.respond_to?(:setter_method?)` asks rubocop-ast's
  # Node, where the cop's own `setter_method?(node)` is a private helper.
  it "leaves a probe of a method the project defines only privately, or outside any class" do
    expect_no_offenses(<<~RUBY)
      def outline = nil
      class VoidCheck
        def tagged(node) = node.respond_to?(:modifier_form?) && node.respond_to?(:setter_method?)
        def drawn(node) = node.respond_to?(:outline) || node.respond_to?(:sealed?) || node.respond_to?(:kept)
        protected def sealed? = true
        private
        def setter_method?(node) = node.method_name.end_with?("=")
        def kept = nil
        public
        def modifier_form?(node) = node.loc.end.nil?
        private :modifier_form?, "kept"
      end
    RUBY
  end

  it "flags a probe of a module function or a class method the project defines" do
    expect_offense(<<~RUBY)
      module Tools
        module_function

        def sharpen = nil
        def self.hone = nil
      end
      def ready?(tool) = tool.respond_to?(:sharpen) || tool.respond_to?(:hone)
                              ^^^^^^^^^^^ `respond_to?` asks an object what it is; tell it what to do, and let polymorphism choose.
                                                            ^^^^^^^^^^^ `respond_to?` asks an object what it is; tell it what to do, and let polymorphism choose.
    RUBY
  end

  it "flags a probe that asks for private methods too, and one of a method made public again" do
    expect_offense(<<~RUBY)
      class VoidCheck
        private
        def setter_method?(node) = node.method_name.end_with?("=")
        def self.vetted = true
        public
        def modifier_form?(node) = node.loc.end.nil?
        class << self
          def shelved = new
        end
      end
      def tagged(node) = node.respond_to?(:setter_method?, true) || node.respond_to?(:modifier_form?)
                              ^^^^^^^^^^^ `respond_to?` asks an object what it is; tell it what to do, and let polymorphism choose.
                                                                         ^^^^^^^^^^^ `respond_to?` asks an object what it is; tell it what to do, and let polymorphism choose.
      def made(kind) = kind.respond_to?(:shelved) && kind.respond_to?(:vetted)
                            ^^^^^^^^^^^ `respond_to?` asks an object what it is; tell it what to do, and let polymorphism choose.
                                                          ^^^^^^^^^^^ `respond_to?` asks an object what it is; tell it what to do, and let polymorphism choose.
    RUBY
  end

  it "makes private only the method of the class that says so" do
    expect_offense(<<~RUBY)
      class Outer
        class Inner
          def shown = 1
        end
        def shown = 2
        private :shown, :ghost
      end
      def shown?(node) = node.respond_to?(:shown) || node.respond_to?(:ghost, true)
                              ^^^^^^^^^^^ `respond_to?` asks an object what it is; tell it what to do, and let polymorphism choose.
    RUBY
  end

  # pundit: `::RSpec.respond_to?(:current_example)` guards its own polyfill of that method.
  it "leaves a probe of a foreign constant, even for a method the project defines" do
    expect_offense(<<~RUBY)
      module Matchers
        def current_example = nil
        Ok = Module.new
      end
      def polyfilled? = ::RSpec.respond_to?(:current_example) || Matchers::Ok.respond_to?(:current_example)
                                                                              ^^^^^^^^^^^ `respond_to?` asks an object what it is; tell it what to do, and let polymorphism choose.
    RUBY
  end

  # action_policy: `"".respond_to?(:safe_constantize)` asks whether ActiveSupport extended String; the project's
  # own `safe_constantize` lives in `refine String do`, which no object answers respond_to? for.
  it "leaves a probe of a literal, a core object, and of a method only a refinement defines" do
    expect_offense(<<~RUBY)
      module Ext
        refine String do
          def safe_constantize = nil
        end
        refine(Integer, &PATCH)
        def lookup = nil
        helpers(String) { def chase = nil }
      end
      def polyfilled? = "".respond_to?(:safe_constantize) || [].respond_to?(:lookup) || 1.respond_to?(:lookup)
      def ready?(item) = item.respond_to?(:safe_constantize) || item.respond_to?(:lookup)
                                                                     ^^^^^^^^^^^ `respond_to?` asks an object what it is; tell it what to do, and let polymorphism choose.
      def chased?(item) = item.respond_to?(:chase)
                               ^^^^^^^^^^^ `respond_to?` asks an object what it is; tell it what to do, and let polymorphism choose.
    RUBY
  end

  context "with the project's dependencies" do
    let(:cop_config) do
      gems = %w[rack rubocop rubocop-ast rack_attack]
      { "AllowedMethods" => [], "OwnedPaths" => [], "Dependencies" => gems, "Roots" => %w[Rubocop::Kata] }
    end

    it "leaves a class a dependency owns, however the project reopens it" do
      expect_offense(<<~RUBY)
        module Rack
          class Request
            def client_address = get_header("REMOTE_ADDR")
          end
        end
        class RuboCop::AST::Node
          def outline = nil
        end
        class RuboCop::Kata::Waiver
          def lifted = nil
        end
        class Racket; end
        module Rack
          def self.version = 3
        end
        class RackAttack::Throttle; end
        def rack?(app) = app.is_a?(Rack) || app.is_a?(RackAttack::Throttle)
        def open?(request) = request.is_a?(Rack::Request) || request.respond_to?(:client_address)
        def node?(node) = node.is_a?(RuboCop::AST::Node) || node.respond_to?(:outline) || node.is_a?(Racket)
                                                                                               ^^^^^ `is_a?` asks an object what it is; tell it what to do, and let polymorphism choose.
        def waived?(waiver) = waiver.is_a?(RuboCop::Kata::Waiver) || waiver.respond_to?(:lifted)
                                     ^^^^^ `is_a?` asks an object what it is; tell it what to do, and let polymorphism choose.
                                                                            ^^^^^^^^^^^ `respond_to?` asks an object what it is; tell it what to do, and let polymorphism choose.
      RUBY
    end
  end

  it "leaves probes for IO and reflection protocols, even where the project defines the method" do
    expect_no_offenses(<<~RUBY)
      def read = @io.read
      def rewind = @io.rewind
      def superclass = @parent
      def name = @name
      def load(source) = source.respond_to?(:read) ? source.read : File.read(source)
      def reset(io) = io.rewind if io.respond_to?(:rewind)
      def lineage(klass) = klass.respond_to?(:superclass) && klass.respond_to?(:name)
    RUBY
  end

  context "with the project's other files" do
    include TabledCop

    let(:root) { Dir.mktmpdir("kata-types") }
    let(:cop) do
      shipped = { "Kata/NoTypeCheck" => { "OwnedPaths" => ["lib/**/*.rb"], "AllowedMethods" => [] } }
      described_class.new(RuboCop::Config.new(shipped, File.join(root, ".rubocop.yml")))
    end

    before do
      FileUtils.mkdir_p(File.join(root, "lib", "billing"))
      invoice = "module Billing\n  class Invoice\n    def settle = nil\n  end\n  Draft = Struct.new(:id)\nend\n"
      File.write(File.join(root, "lib", "billing", "invoice.rb"), invoice)
      File.write(File.join(root, "lib", "billing", "cart.rb"), "class Shop::Cart\nend\n")
      refund = "Billing::Refund =\n  Class.new(StandardError) do\n  end\n"
      File.write(File.join(root, "lib", "billing", "refund.rb"), refund)
      helper = "class Billing::Ledger\n  private\n\n  def reconcile = nil\nend\n"
      File.write(File.join(root, "lib", "billing", "ledger.rb"), helper)
    end

    after { FileUtils.rm_rf(root) }

    it "knows the types and methods defined in OwnedPaths" do
      probes = %w[
        is_a?(Billing::Invoice) is_a?(Billing::Draft) respond_to?(:settle) is_a?(Hash) is_a?(Shop::Cart)
        is_a?(Billing::Refund) is_a?(Draft)
      ]
      found = offenses(probes.map { "x.#{it}\n" }.join)
      expect(found.map(&:line)).to(eq([1, 2, 3, 5, 6]))
    end

    it "knows which of their methods are private" do
      expect(offenses("x.respond_to?(:reconcile)\nx.respond_to?(:reconcile, true)\n").map(&:line)).to(eq([2]))
    end
  end
end
