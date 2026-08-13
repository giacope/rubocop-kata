# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::NoAbbreviation, :config) do
  let(:cop_config) { { "BannedNames" => %w[usr cfg res] } }

  it "flags abbreviated parameters and locals, digits included" do
    expect_offense(<<~RUBY)
      def load(usr, cfg: nil)
               ^^^ `usr` is an abbreviation; spell the word out.
                    ^^^ `cfg` is an abbreviation; spell the word out.
        res2 = usr
        ^^^^ `res2` is an abbreviation; spell the word out.
      end
    RUBY
  end

  it "allows spelled-out names" do
    expect_no_offenses(<<~RUBY)
      def load(user, config: nil)
        result = user
      end
    RUBY
  end
end
