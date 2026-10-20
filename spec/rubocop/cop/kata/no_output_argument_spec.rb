# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::NoOutputArgument, :config) do
  let(:ruby_version) { 3.4 }

  let(:cop_config) do
    { "AllowedNames" => %w[io], "MutatingMethods" => %w[<< []= delete push sort!] }
  end

  it "flags a mutating call on a parameter" do
    expect_offense(<<~RUBY)
      def collect(node, found, options = {}, key:, limit: 3)
        found << node
        ^^^^^^^^^^^^^ `<<` changes the caller's `found`; return a new value, or move the change to the object that owns it.
        options.delete(:depth)
        ^^^^^^^^^^^^^^^^^^^^^^ `delete` changes the caller's `options`; return a new value, or move the change to the object that owns it.
        key.push(1)
        ^^^^^^^^^^^ `push` changes the caller's `key`; return a new value, or move the change to the object that owns it.
        limit&.sort!
        ^^^^^^^^^^^^ `sort!` changes the caller's `limit`; return a new value, or move the change to the object that owns it.
      end
    RUBY
  end

  it "flags writing into a parameter by index, plainly or with an operator" do
    expect_offense(<<~RUBY)
      def self.tally(counts, word)
        counts[word] = 0
        ^^^^^^^^^^^^^^^^ `[]=` changes the caller's `counts`; return a new value, or move the change to the object that owns it.
        counts[word] += 1
        ^^^^^^^^^^^^ `[]=` changes the caller's `counts`; return a new value, or move the change to the object that owns it.
        counts[word] ||= 1
        ^^^^^^^^^^^^ `[]=` changes the caller's `counts`; return a new value, or move the change to the object that owns it.
      end
    RUBY
  end

  it "allows reading a parameter, and reading from it by index" do
    expect_no_offenses(<<~RUBY)
      def total(counts, word)
        found = counts[word]
        best ||= counts[word]
        counts.fetch(word) + found + best
      end
    RUBY
  end

  it "allows changing locals, state, splats, and allowed sinks" do
    expect_no_offenses(<<~RUBY)
      def render(io, *parts, **options, &block)
        lines = []
        lines << parts.shift
        @lines << lines
        parts.push(1)
        options.delete(:x)
        block << 1
        io << lines.join
      end
    RUBY
  end

  it "allows a parameter reassigned before the change" do
    expect_no_offenses(<<~RUBY)
      def normalize(options)
        options = options.dup
        options.delete(:depth)
      end
    RUBY
  end

  it "flags the change made before the parameter is reassigned" do
    expect_offense(<<~RUBY)
      def normalize(options)
        options.delete(:depth)
        ^^^^^^^^^^^^^^^^^^^^^^ `delete` changes the caller's `options`; return a new value, or move the change to the object that owns it.
        options = {}
        options
      end
    RUBY
  end

  it "allows a block parameter that shadows the method's" do
    expect_no_offenses(<<~RUBY)
      def fill(rows)
        rows.map { |rows| rows << 1 }
        rows.each { |(row, rows)| rows << row }
        rows.each { |row; rows| rows = []; rows << row }
      end
    RUBY
  end

  it "still flags the parameter inside a block that does not shadow it" do
    expect_offense(<<~RUBY)
      def fill(rows, cells)
        cells.each { |cell| rows << cell }
                            ^^^^^^^^^^^^ `<<` changes the caller's `rows`; return a new value, or move the change to the object that owns it.
        cells.each { rows << it }
                     ^^^^^^^^^^ `<<` changes the caller's `rows`; return a new value, or move the change to the object that owns it.
      end
    RUBY
  end

  it "leaves a nested method or class to its own scope" do
    expect_no_offenses(<<~RUBY)
      def build(rows)
        Class.new do
          def add(row) = rows << row
        end
        class << self
          rows << 1
        end
        def self.add(row) = rows << row
      end
    RUBY
  end

  it "allows a method without a body or parameters" do
    expect_no_offenses(<<~RUBY)
      def nothing(rows); end
      def plain = items << 1
    RUBY
  end
end
