# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::NoTypeCheck, :config) do
  let(:ruby_version) { 3.4 }

  let(:cop_config) { { "AllowedMethods" => %w[== coerce] } }

  it "flags asking an object what it is" do
    expect_offense(<<~RUBY)
      def render(value)
        return value.to_s if value.is_a?(Symbol)
                                   ^^^^^ `is_a?` asks an object what it is; tell it what to do, and let polymorphism choose.
        return value.call if value.respond_to?(:call)
                                   ^^^^^^^^^^^ `respond_to?` asks an object what it is; tell it what to do, and let polymorphism choose.
        return value if value.kind_of?(String) || value.instance_of?(Array)
                              ^^^^^^^^ `kind_of?` asks an object what it is; tell it what to do, and let polymorphism choose.
                                                        ^^^^^^^^^^^^ `instance_of?` asks an object what it is; tell it what to do, and let polymorphism choose.
      end
    RUBY
  end

  it "flags a check outside any method" do
    expect_offense(<<~RUBY)
      HANDLER = value.is_a?(Proc) ? value : proc { value }
                      ^^^^^ `is_a?` asks an object what it is; tell it what to do, and let polymorphism choose.
    RUBY
  end

  it "allows the protocols that must check what they were handed" do
    expect_no_offenses(<<~RUBY)
      def ==(other) = other.is_a?(Money) && cents == other.cents
      def self.coerce(other) = other.respond_to?(:to_money) ? other.to_money : other
    RUBY
  end

  it "leaves other predicates alone" do
    expect_no_offenses(<<~RUBY)
      value.nil?
      value.empty?
      Money === value
    RUBY
  end
end
