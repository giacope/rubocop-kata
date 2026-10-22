# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::ClockDiscipline, :config) do
  let(:ruby_version) { 3.4 }

  it "flags reads of the ambient clock" do
    expect_offense(<<~RUBY)
      def stamp
        Time.now
        ^^^^^^^^ Inject a clock; `Time.now` reads the ambient time.
        Date.today
        ^^^^^^^^^^ Inject a clock; `Date.today` reads the ambient time.
        ::Time.current
        ^^^^^^^^^^^^^^ Inject a clock; `::Time.current` reads the ambient time.
        DateTime.now
        ^^^^^^^^^^^^ Inject a clock; `DateTime.now` reads the ambient time.
        Date.current
        ^^^^^^^^^^^^ Inject a clock; `Date.current` reads the ambient time.
        Date.yesterday
        ^^^^^^^^^^^^^^ Inject a clock; `Date.yesterday` reads the ambient time.
        Date.tomorrow
        ^^^^^^^^^^^^^ Inject a clock; `Date.tomorrow` reads the ambient time.
      end
    RUBY
  end

  it "flags the zone clock Rails reads through" do
    expect_offense(<<~RUBY)
      def stamp
        Time.zone.now
        ^^^^^^^^^^^^^ Inject a clock; `Time.zone.now` reads the ambient time.
        ::Time.zone.today
        ^^^^^^^^^^^^^^^^^ Inject a clock; `::Time.zone.today` reads the ambient time.
      end
    RUBY
  end

  it "flags Time.new without arguments, which is now, and the process clock" do
    expect_offense(<<~RUBY)
      def stamp
        Time.new
        ^^^^^^^^ Inject a clock; `Time.new` reads the ambient time.
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Inject a clock; `Process.clock_gettime(Process::CLOCK_MONOTONIC)` reads the ambient time.
      end
    RUBY
  end

  it "takes code outside every class, module and method for a script's boot layer" do
    expect_no_offenses(<<~RUBY)
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      at_exit { puts(Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) }
    RUBY
  end

  it "flags the clock in a module body" do
    expect_offense(<<~RUBY)
      module Boot
        STARTED = Time.now
                  ^^^^^^^^ Inject a clock; `Time.now` reads the ambient time.
      end
    RUBY
  end

  it "allows a time built from its parts" do
    expect_no_offenses(<<~RUBY)
      Time.new(1970, 1, 1)
      Time.at(0)
      Time.zone.parse("2020-01-01")
    RUBY
  end

  it "allows the clock as a parameter default, which is the seam it asks for" do
    expect_no_offenses(<<~RUBY)
      def stamp(now: Time.now) = now.iso8601

      def mark(today = Date.today) = today

      def zone(now: Time.zone.now) = now
    RUBY
  end

  it "still flags the clock in a default's body elsewhere" do
    expect_offense(<<~RUBY)
      def stamp(now: nil)
        (now || Time.now).iso8601
                ^^^^^^^^ Inject a clock; `Time.now` reads the ambient time.
      end
    RUBY
  end

  it "allows an injected clock" do
    expect_no_offenses(<<~RUBY)
      @clock.now
      calendar.today
      Clock.now
    RUBY
  end
end
