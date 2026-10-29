# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::ClockDiscipline, :config) do
  let(:ruby_version) { 3.4 }
  let(:cop_config) { { "CheckRandomness" => true } }

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

  # R6B5-K2: a call through `&.` is the same call.
  it "reads a clock or a draw through safe navigation" do
    expect_offense(<<~RUBY)
      def stamp
        Time.zone&.now
        ^^^^^^^^^^^^^^ Inject a clock; `Time.zone&.now` reads the ambient time.
        @names&.sample
        ^^^^^^^^^^^^^^ Pass `sample` an injected generator (`random: @random`); without one it draws from the ambient source.
        @names&.shuffle(random: @random)
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

  # The V1 conformance case P34: an invoice numbered with SecureRandom.
  it "flags ambient randomness" do
    expect_offense(<<~RUBY)
      def number
        SecureRandom.hex(4)
        ^^^^^^^^^^^^^^^^^^^ Inject a source of randomness; `SecureRandom.hex` draws from the ambient one.
        ::SecureRandom.uuid
        ^^^^^^^^^^^^^^^^^^^ Inject a source of randomness; `::SecureRandom.uuid` draws from the ambient one.
        rand(10)
        ^^^^^^^^ Inject a source of randomness; `rand` draws from the ambient one.
        Kernel.rand
        ^^^^^^^^^^^ Inject a source of randomness; `Kernel.rand` draws from the ambient one.
        Random.rand(1..6)
        ^^^^^^^^^^^^^^^^^ Inject a source of randomness; `Random.rand` draws from the ambient one.
        Random.new_seed
        ^^^^^^^^^^^^^^^ Inject a source of randomness; `Random.new_seed` draws from the ambient one.
        Random.new
        ^^^^^^^^^^ Inject a source of randomness; `Random.new` draws from the ambient one.
      end
    RUBY
  end

  it "flags a draw from a collection without an injected generator" do
    expect_offense(<<~RUBY)
      def pick
        @names.sample
        ^^^^^^^^^^^^^ Pass `sample` an injected generator (`random: @random`); without one it draws from the ambient source.
        NAMES.shuffle(1)
        ^^^^^^^^^^^^^^^^ Pass `shuffle` an injected generator (`random: @random`); without one it draws from the ambient source.
        list.shuffle!
        ^^^^^^^^^^^^^ Pass `shuffle!` an injected generator (`random: @random`); without one it draws from the ambient source.
        list.sample(2, seed: 1)
        ^^^^^^^^^^^^^^^^^^^^^^^ Pass `sample` an injected generator (`random: @random`); without one it draws from the ambient source.
      end
    RUBY
  end

  it "allows a seeded or injected source of randomness" do
    expect_no_offenses(<<~RUBY)
      def pick
        @names.sample(random: @random)
        @names.shuffle(2, random: Random.new(42))
        Random.new(42).rand
        @random.rand(10)
        sample
        srand(42)
      end

      def number(serial: SecureRandom.hex(4)) = serial
    RUBY
  end

  # ffaker's RandomUtils#rand reads its own seeded FFaker::Random.
  it "leaves a rand the file defines, and a draw one of its modules answers" do
    expect_no_offenses(<<~RUBY)
      module FFaker
        module ArrayUtils
          def self.shuffle(list) = list.sort_by { FFaker::Random.rand }
        end

        module RandomUtils
          def rand(max = nil) = FFaker::Random.rand(max)
          def digit = rand(9)
          def mixed = ArrayUtils.shuffle([1, 2])
        end
      end
    RUBY
  end

  # kimera's eval Shell#finish (fp/kimera-1): `peak = Peak.new(pid)` then `peak.sample`, Peak's own method.
  it "leaves a draw's name sent to an instance of a class the project defines with that method" do
    expect_no_offenses(<<~RUBY)
      class Peak
        def sample = @sizes << File.size(@path)
      end

      class Shell
        def finish(waiter)
          peak = Peak.new(waiter.pid)
          Thread.new { peak.sample until waiter.join(0.05) }
          @peak.sample
          sampler.sample
          Peak.new(1).sample
        end

        def initialize
          @peak = Peak.new(0)
        end

        def sampler = @_sampler ||= Peak.new(2)
      end
    RUBY
  end

  it "still flags a draw sent to a receiver of unknown class, or to a class without that method" do
    expect_offense(<<~RUBY)
      class Peak
        def sample = @sizes << File.size(@path)
      end

      class Shell
        def watch(peak) = peak.sample
                          ^^^^^^^^^^^ Pass `sample` an injected generator (`random: @random`); without one it draws from the ambient source.
        def mixed = Peak.new(1).shuffle
                    ^^^^^^^^^^^^^^^^^^^ Pass `shuffle` an injected generator (`random: @random`); without one it draws from the ambient source.

        def finish(waiter)
          peak = Peak.new(waiter.pid)
          peak = @peaks if waiter.nil?
          peak.sample
          ^^^^^^^^^^^ Pass `sample` an injected generator (`random: @random`); without one it draws from the ambient source.
        end

        PEAKS = [1].map do |pid|
          peak = Peak.new(pid)
          peak.sample
          ^^^^^^^^^^^ Pass `sample` an injected generator (`random: @random`); without one it draws from the ambient source.
        end
      end
    RUBY
  end

  context "without CheckRandomness, as kata ships it" do
    let(:cop_config) { {} }

    it "reads the clock only" do
      expect_offense(<<~RUBY)
        def number
          Time.now
          ^^^^^^^^ Inject a clock; `Time.now` reads the ambient time.
          SecureRandom.hex(4)
          rand(10)
          @names.sample
        end
      RUBY
    end
  end

  context "with the project's files" do
    include ProjectFiles

    let(:setting) { { "Kata/ClockDiscipline" => cop_config.merge("OwnedPaths" => ["lib/**/*.rb"]) } }

    it "leaves a rand and a module's draw the project defines in another file" do
      files = {
        "lib/ffaker/random_utils.rb" => "module FFaker\n  module RandomUtils\n    def rand(max) = max\n  end\nend\n",
        "lib/ffaker/array_utils.rb" => "module FFaker\n  module ArrayUtils\n  end\nend\n",
        "lib/ffaker/name.rb" =>
          "module FFaker\n  module Name\n    def a = rand(9)\n    def b = ArrayUtils.shuffle(1)\n  end\nend\n"
      }
      expect(project_offenses(files, "lib/ffaker/name.rb")).to(be_empty)
    end
  end
end
