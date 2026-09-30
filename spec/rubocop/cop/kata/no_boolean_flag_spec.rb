# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::NoBooleanFlag, :config) do
  let(:cop_config) { { "AllowedMethods" => %w[respond_to? respond_to_missing? fetch] } }

  it "flags positional boolean arguments" do
    expect_offense(<<~RUBY)
      process(items, true)
                     ^^^^ A boolean flag is two methods trapped in one; split them or name the argument.
    RUBY
  end

  it "allows keyword booleans, comparisons, and assignments" do
    expect_no_offenses(<<~RUBY)
      process(items, dry_run: true)
      done == true
      config.verbose = false
    RUBY
  end

  it "allows the methods whose boolean is a protocol or a value, not a flag" do
    expect_no_offenses(<<~RUBY)
      respond_to?(name, true)
      options.fetch(:ssl, false)
    RUBY
  end

  it "flags a positional parameter that defaults to a boolean, on either kind of def" do
    expect_offense(<<~RUBY)
      def process(items, strict = false, verbose: true)
                         ^^^^^^^^^^^^^^ `strict` defaults to a boolean flag, two methods trapped in one; split them or make it a keyword.
      end
      def self.build(items, strict = true)
                            ^^^^^^^^^^^^^ `strict` defaults to a boolean flag, two methods trapped in one; split them or make it a keyword.
      end
    RUBY
  end

  it "allows other defaults, and the parameters of an allowed method" do
    expect_no_offenses(<<~RUBY)
      def process(items, limit = 10, mode = nil)
      end
      def respond_to_missing?(name, include_private = false)
      end
    RUBY
  end
end
