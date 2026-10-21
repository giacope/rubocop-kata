# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::NoEmptyLinesInMethods, :config) do
  let(:ruby_version) { 3.4 }

  it "flags and removes a blank line in a method body" do
    expect_offense(<<~RUBY)
      def total
        sum = 1

      ^{} Empty line inside method body is not allowed
        sum + 1
      end
    RUBY
    expect_correction(<<~RUBY)
      def total
        sum = 1
        sum + 1
      end
    RUBY
  end

  it "flags a blank line in a singleton method" do
    expect_offense(<<~RUBY)
      def self.total
        sum = 1

      ^{} Empty line inside method body is not allowed
        sum + 1
      end
    RUBY
  end

  it "keeps the blank lines of a heredoc, beside a blank line it removes" do
    expect_offense(<<~RUBY)
      def render(type)
        lines = []

      ^{} Empty line inside method body is not allowed
        if type
          lines << <<~MD
            `\#{type}`

            ----
          MD
        end
        lines.join
      end
    RUBY
    expect_correction(<<~RUBY)
      def render(type)
        lines = []
        if type
          lines << <<~MD
            `\#{type}`

            ----
          MD
        end
        lines.join
      end
    RUBY
  end

  it "keeps the blank lines of a plain heredoc and of a multi-line string" do
    expect_no_offenses(<<~RUBY)
      def body
        <<~TEXT
          Hello,

          Your claim was received.
        TEXT
      end

      def note
        "first

      second"
      end

      def shell
        `echo a

      echo b`
      end
    RUBY
  end

  it "keeps the blank line of a heredoc Ruby reads as one string" do
    expect_no_offenses(<<~RUBY)
      def body
        <<-TEXT
          Hello,

          Bye
        TEXT
      end
    RUBY
  end

  it "leaves a file with no code alone" do
    expect_no_offenses("# frozen_string_literal: true\n")
  end

  it "leaves a method with no body, or a one-line body, alone" do
    expect_no_offenses(<<~RUBY)
      def none; end

      def one = 1

      def two
        1
      end
    RUBY
  end
end
