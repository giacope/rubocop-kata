# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::ClockDiscipline, :config) do
  it "flags reads of the ambient clock" do
    expect_offense(<<~RUBY)
      Time.now
      ^^^^^^^^ Inject a clock; `Time.now` reads the ambient time.
      Date.today
      ^^^^^^^^^^ Inject a clock; `Date.today` reads the ambient time.
      ::Time.current
      ^^^^^^^^^^^^^^ Inject a clock; `Time.current` reads the ambient time.
    RUBY
  end

  it "allows an injected clock" do
    expect_no_offenses(<<~RUBY)
      @clock.now
      calendar.today
    RUBY
  end
end
