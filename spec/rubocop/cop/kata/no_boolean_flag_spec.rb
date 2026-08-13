# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::NoBooleanFlag, :config) do
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
end
