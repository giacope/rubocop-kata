# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::NoUtilName, :config) do
  let(:cop_config) { { "BannedNames" => %w[Util Helper] } }

  it "flags junk-drawer names, however nested" do
    expect_offense(<<~RUBY)
      module App::Util
             ^^^^^^^^^ `Util` is a junk drawer; it hides the concept the code is missing.
      end
      class Helper
            ^^^^^^ `Helper` is a junk drawer; it hides the concept the code is missing.
      end
    RUBY
  end

  it "allows names that merely contain the word" do
    expect_no_offenses(<<~RUBY)
      class HelperText
      end
      class Utility
      end
    RUBY
  end
end
