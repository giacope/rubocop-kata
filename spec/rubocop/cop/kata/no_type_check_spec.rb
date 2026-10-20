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
    end

    after { FileUtils.rm_rf(root) }

    it "knows the types and methods defined in OwnedPaths" do
      found = offenses("x.is_a?(Billing::Invoice)\nx.is_a?(Draft)\nx.respond_to?(:settle)\nx.is_a?(Hash)\n")
      expect(found.map(&:line)).to(eq([1, 2, 3]))
    end
  end
end
