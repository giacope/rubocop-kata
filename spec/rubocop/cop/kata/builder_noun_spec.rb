# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::BuilderNoun, :config) do
  let(:cop_config) { { "BannedPrefixes" => %w[get calculate] } }

  it "flags verb-prefixed builders" do
    expect_offense(<<~RUBY)
      def calculate_total
          ^^^^^^^^^^^^^^^ A builder is named for what it returns: `total`, not `calculate_total`.
      end
      def self.get_name
               ^^^^^^^^ A builder is named for what it returns: `name`, not `get_name`.
      end
    RUBY
  end

  it "allows nouns and bare verbs" do
    expect_no_offenses(<<~RUBY)
      def total
      end
      def calculate
      end
      def getaway
      end
    RUBY
  end
end
