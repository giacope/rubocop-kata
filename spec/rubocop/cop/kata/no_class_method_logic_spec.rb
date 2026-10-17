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

    it "still flags a query on the class" do
      expect_offense(<<~RUBY)
        class Money
          def self.active = all.select(&:active?)
                   ^^^^^^ `active` puts logic on the class; classes construct, instances work.
        end
      RUBY
    end
  end
end
