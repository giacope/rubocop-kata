# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::IoDiscipline, :config) do
  it "flags bare output calls" do
    expect_offense(<<~RUBY)
      puts "report"
      ^^^^^^^^^^^^^ Write through the injected `@io`, not bare `puts`.
      warn "oops"
      ^^^^^^^^^^^ Write through the injected `@io`, not bare `warn`.
    RUBY
  end

  it "allows writing through a receiver" do
    expect_no_offenses(<<~RUBY)
      @io.puts "report"
      $stderr.puts "oops"
    RUBY
  end
end
