# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::EnvDiscipline, :config) do
  it "flags ENV reads" do
    expect_offense(<<~RUBY)
      ENV["HOME"]
      ^^^ `ENV` belongs in the boot layer; pass configuration in.
      ::ENV.fetch("HOME")
      ^^^^^ `ENV` belongs in the boot layer; pass configuration in.
    RUBY
  end

  it "allows configuration passed in" do
    expect_no_offenses(<<~RUBY)
      configuration.home
    RUBY
  end
end
