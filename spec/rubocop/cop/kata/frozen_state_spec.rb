# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::FrozenState, :config) do
  let(:ruby_version) { 3.4 }

  it "flags state assigned after construction" do
    expect_offense(<<~RUBY)
      class Account
        def initialize(balance)
          @balance = balance
        end

        def deposit(amount)
          @balance += amount
          ^^^^^^^^ `@balance` changes after construction; set state once in `initialize` and return a new object to change it.
        end

        def close
          @closed, @balance = true, 0
          ^^^^^^^ `@closed` changes after construction; set state once in `initialize` and return a new object to change it.
                   ^^^^^^^^ `@balance` changes after construction; set state once in `initialize` and return a new object to change it.
        end
      end
    RUBY
  end

  it "allows the constructors Ruby calls" do
    expect_no_offenses(<<~RUBY)
      class Account
        def initialize(balance) = @balance = balance
        def initialize_copy(other) = @balance = other.balance.dup
        def initialize_dup(other) = @copied = true
        def initialize_clone(other, freeze: nil) = @cloned = true
      end
    RUBY
  end

  it "allows a helper only the constructor calls, however deep" do
    expect_no_offenses(<<~RUBY)
      class Account
        def initialize(rows)
          load(rows)
        end

        private

        def load(rows)
          @rows = rows
          index
        end

        def index = @index = @rows.to_h
      end
    RUBY
  end

  it "flags a helper the constructor does not call" do
    expect_offense(<<~RUBY)
      class Account
        def initialize(rows) = load(rows)

        def load(rows) = @rows = rows

        def reset = @rows = []
                    ^^^^^ `@rows` changes after construction; set state once in `initialize` and return a new object to change it.
      end
    RUBY
  end

  it "flags a method outside any class, which no constructor calls" do
    expect_offense(<<~RUBY)
      def reset = @rows = []
                  ^^^^^ `@rows` changes after construction; set state once in `initialize` and return a new object to change it.
    RUBY
  end

  it "allows memoization" do
    expect_no_offenses(<<~RUBY)
      class Report
        def rows = @rows ||= load
        def total = @total = @total || sum
        def header
          return @header if defined?(@header)
          @header = build
        end
        def footer
          @footer = build unless @footer
          @footer
        end
        def summary
          @summary = build if @summary.nil?
          @summary
        end
        def legend
          @legend = build if !@legend || stale?
          @legend
        end
        def index
          @index = build unless instance_variable_defined?(:@index)
          @index
        end
        def links
          @links = build if !defined?(@links)
          @links
        end
        def notes
          @notes = build unless self.instance_variable_defined?(:@notes)
          @notes
        end
        def title
          @title = build if @title.blank?
          @title
        end
        def caption
          @caption = build unless @caption && fresh?
          @caption
        end
      end
    RUBY
  end

  it "flags a guarded assignment whose guard is not about the variable" do
    expect_offense(<<~RUBY)
      class Report
        def refresh
          @rows = load if stale? && @rows.any?
          ^^^^^ `@rows` changes after construction; set state once in `initialize` and return a new object to change it.
          @total = @count || sum
          ^^^^^^ `@total` changes after construction; set state once in `initialize` and return a new object to change it.
          @mode = :open if @mode == :closed
          ^^^^^ `@mode` changes after construction; set state once in `initialize` and return a new object to change it.
          @rows &&= nil
          ^^^^^ `@rows` changes after construction; set state once in `initialize` and return a new object to change it.
        end

        def matched?
          @match = candidates.first
          ^^^^^^ `@match` changes after construction; set state once in `initialize` and return a new object to change it.
          !@match.nil? && defined?(@other)
        end
      end
    RUBY
  end

  it "leaves class-level state and code outside methods to other cops" do
    expect_no_offenses(<<~RUBY)
      class Registry
        @entries = {}

        def self.register(entry) = @entries = entry

        class << self
          def reset = @entries = {}
        end

        included { @flag = true }
      end
    RUBY
  end

  it "judges a method in a block-built class by that block's constructor" do
    expect_offense(<<~RUBY)
      Class.new do
        def initialize = @rows = []
        def reset = @rows = []
                    ^^^^^ `@rows` changes after construction; set state once in `initialize` and return a new object to change it.
      end
    RUBY
  end

  it "allows a hook the superclass's constructor calls, when the superclass is in the file" do
    expect_no_offenses(<<~RUBY)
      class Model
        def initialize(raw)
          @raw = raw
          setup
        end

        def setup = nil
      end

      class Version < Model
        def setup
          @status = @raw.fetch("status")
        end
      end

      class Draft < Version
        def setup = @kind = :draft
      end
    RUBY
  end

  it "still flags the same hook name in a class that does not inherit it" do
    expect_offense(<<~RUBY)
      class Model
        def initialize = setup
        def setup = nil
      end

      class Other < Base
        def setup = @status = :open
                    ^^^^^^^ `@status` changes after construction; set state once in `initialize` and return a new object to change it.
      end

      class Loop < Loop
        def setup = @status = :open
                    ^^^^^^^ `@status` changes after construction; set state once in `initialize` and return a new object to change it.
      end
    RUBY
  end

  context "with a hook a superclass elsewhere calls" do
    let(:cop_config) { { "ConstructorHooks" => %w[setup] } }

    it "allows the hook it names" do
      expect_no_offenses(<<~RUBY)
        class Version < Spaceship::Base
          def setup = @status = :open
        end
      RUBY
    end
  end

  it "flags state set inside a method define_method mints, or through instance_variable_set" do
    expect_offense(<<~'RUBY')
      class Box
        define_method(:resize) { |depth| @depth = depth }
                                         ^^^^^^ `@depth` changes after construction; set state once in `initialize` and return a new object to change it.
        def reset
          instance_variable_set(:@depth, 0)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `@depth` changes after construction; set state once in `initialize` and return a new object to change it.
        end
        %i[width height].each do |side|
          define_method(:"#{side}=") { |value| self.instance_variable_set(:"@#{side}", value) }
                                               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `:"@#{side}"` changes after construction; set state once in `initialize` and return a new object to change it.
        end
      end
    RUBY
  end

  it "allows instance_variable_set in a constructor, on a copy, or in a minted constructor" do
    expect_no_offenses(<<~RUBY)
      class Box
        def initialize(depth) = instance_variable_set(:@depth, depth)
        def with(depth) = dup.tap { it.instance_variable_set(:@depth, depth) }
        define_method(:initialize_copy) { |other| @depth = other.depth }
        define_method(:depth) { @_depth ||= 1 }
        each { @seen = true }
      end
    RUBY
  end
end
