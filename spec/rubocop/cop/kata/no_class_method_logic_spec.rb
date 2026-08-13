# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::NoClassMethodLogic, :config) do
  let(:cop_config) { { "AllowedNames" => %w[build] } }

  it "flags class methods that carry logic" do
    expect_offense(<<~RUBY)
      def self.total_for(user)
               ^^^^^^^^^ `total_for` puts logic on the class; classes construct, instances work.
        user.total
      end
    RUBY
  end

  it "allows constructors" do
    expect_no_offenses(<<~RUBY)
      def self.build
        new
      end
      def self.from_json(json)
        new(json)
      end
    RUBY
  end
end
