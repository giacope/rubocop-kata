# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::NoClassMethodLogic, :config) do
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
end
