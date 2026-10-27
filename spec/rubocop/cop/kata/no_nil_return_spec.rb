# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::NoNilReturn, :config) do
  let(:ruby_version) { 3.4 }
  let(:cop_config) { { "AllowedMethods" => ["[]"] } }

  it "flags a literal nil, as the last expression or returned" do
    expect_offense(<<~RUBY)
      def find(code)
        return nil unless @items.key?(code)
        ^^^^^^^^^^ `find` returns nil; return a null object, or fail fast.
        @items.fetch(code)
      end

      def self.none
        log
        nil
        ^^^ `none` returns nil; return a null object, or fail fast.
      end
    RUBY
  end

  it "flags the nil a lookup passes on" do
    expect_offense(<<~RUBY)
      def a = @items.detect { |item| item.code == code }
              ^^^^^^^^^^^^^ `a` passes on the nil `detect` can return; return a null object, or fail fast.
      def b = @items.find(&:open)
              ^^^^^^^^^^^^^^^^^^^ `b` passes on the nil `find` can return; return a null object, or fail fast.
      def c = @items.first
              ^^^^^^^^^^^^ `c` passes on the nil `first` can return; return a null object, or fail fast.
      def d = @items[code]
              ^^^^^^^^^^^^ `d` passes on the nil `[]` can return; return a null object, or fail fast.
      def e = @rows.dig(:a, :b)
              ^^^^^^^^^^^^^^^^^ `e` passes on the nil `dig` can return; return a null object, or fail fast.
      def f = find_by(email: @email)
              ^^^^^^^^^^^^^^^^^^^^^^ `f` passes on the nil `find_by` can return; return a null object, or fail fast.
      def g = @owner&.name
              ^^^^^^^^^^^^ `g` passes on the nil `&.name` can return; return a null object, or fail fast.
      def h = @text.match(/x/)
              ^^^^^^^^^^^^^^^^ `h` passes on the nil `match` can return; return a null object, or fail fast.
      def i
        return @items.max if @items.any?
               ^^^^^^^^^^ `i` passes on the nil `max` can return; return a null object, or fail fast.
        @cache ||= @rows.presence
                   ^^^^^^^^^^^^^^ `i` passes on the nil `presence` can return; return a null object, or fail fast.
      end
    RUBY
  end

  it "flags the missing branch of a conditional whose other branches are values" do
    expect_offense(<<~RUBY)
      def find(code)
        @items.fetch(code) if @open
                           ^^ `find` returns nil when this `if` does not hold; answer that case with a null object, or fail fast.
      end

      def label
        "\#{@name}!" unless @name.empty?
                    ^^^^^^ `label` returns nil when this `unless` does not hold; answer that case with a null object, or fail fast.
      end

      def size
        case @kind
        ^^^^ `size` returns nil when this `case` does not hold; answer that case with a null object, or fail fast.
        when :a then 1
        when :b then @count + 1
        end
      end

      def tier
        if @cents > 100
          :gold
        elsif @cents > 10
        ^^^^^ `tier` returns nil when this `elsif` does not hold; answer that case with a null object, or fail fast.
          :silver
        end
      end
    RUBY
  end

  it "looks through begin, rescue and ensure to the value" do
    expect_offense(<<~RUBY)
      def a
        begin
          @rows.last
          ^^^^^^^^^^ `a` passes on the nil `last` can return; return a null object, or fail fast.
        end
      end

      def b
        @rows.sample
        ^^^^^^^^^^^^ `b` passes on the nil `sample` can return; return a null object, or fail fast.
      rescue KeyError
        raise
      ensure
        close
      end

      def c
        case @code
        ^^^^ `c` returns nil when this `case` does not hold; answer that case with a null object, or fail fast.
        when 1
        else "other"
        end
      end
    RUBY
  end

  it "reads a method whose body only ensures" do
    expect_no_offenses(<<~RUBY)
      def stop
      ensure
        @thread.kill
      end
    RUBY
  end

  it "flags a block that ends in nil" do
    expect_offense(<<~RUBY)
      rows.map { |row| nil }
                       ^^^ This block returns nil; return a null object, or fail fast.
      rows.map do
        log
        nil
        ^^^ This block returns nil; return a null object, or fail fast.
      end
    RUBY
  end

  it "allows a lookup that fails fast or answers with a default" do
    expect_no_offenses(<<~RUBY)
      def a = @items.fetch(code)
      def b = @items.fetch(code, @missing)
      def c = @items.first(2)
      def d = @records.find(id)
      def e = Item.find_by!(code: code)
      def f = rows.map { |row| row }
      def g = (@open ? @items.fetch(code) : @missing)
    RUBY
  end

  it "allows a slice, and a hash that answers every key" do
    expect_no_offenses(<<~RUBY)
      class Shelf
        SHELVES = Hash.new { |all, key| all[key] = [] }
        COUNTS = Hash.new(0)

        def initialize
          @index = Hash.new { |all, key| all[key] = key }
        end

        def a = @rows[1..]
        def b = SHELVES[@key]
        def c = COUNTS[@key]
        def d = @index[@key]
        def e = @rows[0...-1]
        def f = @address.split("@").last
        def g = @bio[0, 40]
      end
    RUBY
  end

  it "still flags a hash built without a default" do
    expect_offense(<<~RUBY)
      class Shelf
        NAMES = Hash.new
        LIST = { a: 1 }.freeze

        def a = NAMES[@key]
                ^^^^^^^^^^^ `a` passes on the nil `[]` can return; return a null object, or fail fast.
        def b = LIST[@key]
                ^^^^^^^^^^ `b` passes on the nil `[]` can return; return a null object, or fail fast.
        def c = @rows[@key][1]
                ^^^^^^^^^^^^^^ `c` passes on the nil `[]` can return; return a null object, or fail fast.
        def d = @text[PATTERN, 1]
                ^^^^^^^^^^^^^^^^^ `d` passes on the nil `[]` can return; return a null object, or fail fast.
        def e = @names[@key]
                ^^^^^^^^^^^^ `e` passes on the nil `[]` can return; return a null object, or fail fast.

        def initialize
          @counts = Hash.new(0)
        end
      end
    RUBY
  end

  it "allows a conditional command, whose value nobody reads" do
    expect_no_offenses(<<~RUBY)
      def notify
        @mailer.deliver(@note) if @enabled
      end

      def remember(value)
        @rows << value unless @rows.frozen?
      end

      def store(value)
        @rows[:key] = value if value
      end

      def drop(id)
        Item.find_by(id: id)&.destroy
      end

      def close
        @socket&.close!
      end

      def plain
        if ready
          1
        else
          2
        end
      end

      def empty; end
      def nothing = return
    RUBY
  end

  # strong_migrations' `def e.cause; nil; end`: the end of the cause chain every reader stops on.
  context "with the shipped AllowedMethods" do
    let(:cop_config) { {} }

    it "allows an override of a core method whose contract answers nil" do
      expect_no_offenses(<<~RUBY)
        def error.cause
          nil
        end

        class Version
          def <=>(other) = (@parts <=> other.parts if other.respond_to?(:parts))
          def =~(other) = nil
          def to_ary = nil
          def gets = @lines.shift
          def backtrace = @raised ? @trace : nil
        end
      RUBY
    end

    it "still flags the nil of a method whose name is not a core protocol" do
      expect_offense(<<~RUBY)
        def error.reason
          nil
          ^^^ `reason` returns nil; return a null object, or fail fast.
        end
      RUBY
    end
  end

  it "allows predicates, writers, the protocol a method forwards, and AllowedMethods" do
    expect_no_offenses(<<~RUBY)
      def open? = @items.first
      def name=(value)
        @rows[value]
      end
      def first = @rows.first
      def [](key) = @rows[key]
      def detect(&) = @rows.detect(&)
    RUBY
  end

  it "skips a return of several values, and attributes a lambda's return to the method around it" do
    expect_no_offenses(<<~RUBY)
      def pair
        return 1, nil if ready
        [1, 2]
      end

      def outer
        define_method(:x) do
          return 1
        end
        2
      end
    RUBY
  end
end
