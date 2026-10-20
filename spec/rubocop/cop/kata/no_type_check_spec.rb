# frozen_string_literal: true

require "tmpdir"

RSpec.describe(RuboCop::Cop::Kata::NoTypeCheck, :config) do
  let(:ruby_version) { 3.4 }

  let(:cop_config) { { "AllowedMethods" => %w[== coerce], "OwnedPaths" => [] } }

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

  it "leaves other predicates, and a probe it cannot name, alone" do
    expect_no_offenses(<<~RUBY)
      class Money; end
      value.nil?
      value.empty?
      Money === value
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
    end

    after { FileUtils.rm_rf(root) }

    it "knows the types and methods defined in OwnedPaths" do
      probes = %w[is_a?(Billing::Invoice) is_a?(Draft) respond_to?(:settle) is_a?(Hash) is_a?(Shop::Cart)]
      found = offenses(probes.map { "x.#{it}\n" }.join)
      expect(found.map(&:line)).to(eq([1, 2, 3, 5]))
    end
  end
end
