# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::NoNilReturn, :config) do
  it "flags explicit and trailing nil returns" do
    expect_offense(<<~RUBY)
      def find(id)
        return nil if id.zero?
        ^^^^^^^^^^ Returning nil hands the caller a bomb; raise or return a real object.
        id
      end
      def reset
        @cache = {}
        nil
        ^^^ Returning nil hands the caller a bomb; raise or return a real object.
      end
    RUBY
  end

  it "allows bare return and real values" do
    expect_no_offenses(<<~RUBY)
      def find(id)
        return if id.zero?
        id
      end
    RUBY
  end
end
