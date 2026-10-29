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

  # rubycritic: `[mod.cost, COST_LIMIT].min` answers one of its elements, and a nil cost raises (R6B6-K5).
  it "allows the min or max of an array literal that holds a value that is never nil" do
    expect_no_offenses(<<~RUBY)
      class Score
        LIMIT = 32.0
        FLOOR = "a"

        def limited = [@cost, LIMIT].min
        def floor = [@cost, 0.0].max
        def ranked = [*@costs, 1].max
        def first = [@name, FLOOR, :b].min
      end
    RUBY
  end

  it "still flags the min or max of a collection, or of an array literal that may hold only nil" do
    expect_offense(<<~RUBY)
      class Score
        LIMIT = nil
        TOP = Limits.top
        FLOOR = 1

        def cheapest = @costs.min
                       ^^^^^^^^^^ `cheapest` passes on the nil `min` can return; return a null object, or fail fast.
        def pair = [@cost, @floor].max
                   ^^^^^^^^^^^^^^^^^^^ `pair` passes on the nil `max` can return; return a null object, or fail fast.
        def limited = [@cost, LIMIT, TOP, OTHER].min
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `limited` passes on the nil `min` can return; return a null object, or fail fast.
        def head = [@cost, 1].first
                   ^^^^^^^^^^^^^^^^ `head` passes on the nil `first` can return; return a null object, or fail fast.
        def none = [].max
                   ^^^^^^ `none` passes on the nil `max` can return; return a null object, or fail fast.
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

  # hashira's Shelves#drawn (fp/hashira-2): `Dir[pattern]` is `Dir.glob`, an Array, empty when nothing matches;
  # kata's PairedBrackets#leading (fp/rubocop-kata-1): a pattern that matches the empty string matches every string.
  it "allows a `[]` that always answers: a core class's builder, and a pattern every string matches" do
    expect_no_offenses(<<~'RUBY')
      class Shelf
        def drawn = Dir[File.join(@root, "*")]
        def rows = ::Hash[@pairs]
        def list = Array[@row]
        def tags = Set[@tag]
        def leading = @line[/\A[ \t]*/]
        def gap = @line[/^\s*-?/]
        def spaces = @line[/ {0,3}/]
        def nothing = @line[//]
      end
    RUBY
  end

  it "still flags a constant's `[]`, and a pattern that needs a character, alternates or interpolates" do
    expect_offense(<<~'RUBY')
      class Shelf
        def home = ENV["HOME"]
                   ^^^^^^^^^^^ `home` passes on the nil `[]` can return; return a null object, or fail fast.
        def word = Words[@key]
                   ^^^^^^^^^^^ `word` passes on the nil `[]` can return; return a null object, or fail fast.
        def leading = @line[/\A[ \t]+/]
                      ^^^^^^^^^^^^^^^^^ `leading` passes on the nil `[]` can return; return a null object, or fail fast.
        def either = @line[/a|b*/]
                     ^^^^^^^^^^^^^ `either` passes on the nil `[]` can return; return a null object, or fail fast.
        def held = @line[/\A#{@mark}*/]
                   ^^^^^^^^^^^^^^^^^^^^ `held` passes on the nil `[]` can return; return a null object, or fail fast.
        def tail = @line[/x*\z/, 1]
                   ^^^^^^^^^^^^^^^^ `tail` passes on the nil `[]` can return; return a null object, or fail fast.
        def anchored = @line[/\Gx*/]
                       ^^^^^^^^^^^^^ `anchored` passes on the nil `[]` can return; return a null object, or fail fast.
      end
    RUBY
  end

  # hashira's Kinship#words (fp/hashira-4): the memo builds a hash whose default proc answers every key.
  it "allows a hash with a default that a memo or a field builds" do
    expect_no_offenses(<<~RUBY)
      class Words
        def words(name) = said[name]
        def kept(name) = @kept[name]

        private

        def said = @_said ||= Hash.new { |memo, name| memo[name] = name.split("_") }

        def kept_words
          @kept ||= Hash.new(0)
        end
      end

      class Tally
        def count(name) = counts[name]
        def seen(name) = remembered[name]

        private

        def counts = Hash.new(0)

        def remembered
          @calls += 1
          @_remembered ||= Hash.new { |memo, name| memo[name] = [] }
        end
      end
    RUBY
  end

  it "still flags a hash a memo or a field builds without a default" do
    expect_offense(<<~RUBY)
      class Words
        def words(name) = said[name]
                          ^^^^^^^^^^ `words` passes on the nil `[]` can return; return a null object, or fail fast.
        def read(name) = loaded(1)[name]
                         ^^^^^^^^^^^^^^^ `read` passes on the nil `[]` can return; return a null object, or fail fast.
        def kept(name) = @kept[name]
                         ^^^^^^^^^^^ `kept` passes on the nil `[]` can return; return a null object, or fail fast.

        private

        def said = @_said ||= {}
        def loaded(_count) = Hash.new(0)
        def keep = @kept += 1
      end

      class Reader
        def read(name) = @shelf.heard[name]
                         ^^^^^^^^^^^^^^^^^^ `read` passes on the nil `[]` can return; return a null object, or fail fast.

        private

        def heard = @_heard ||= Hash.new { |memo, name| memo[name] = [] }
      end
    RUBY
  end

  # kimera's Patience#limit (fp/kimera-5): `clamp` answers a number or raises, so the max answers one, never nil.
  it "allows the min or max of an array literal that holds a number a call computes" do
    expect_no_offenses(<<~RUBY)
      class Patience
        def limit(raised) = [@seconds, raised.clamp(..(@hard - 1.0))].max
        def low(raised) = [@seconds, raised * 3].min
        def least = [@floor, -@ceiling, @rows.size, @text.to_i].min
      end
    RUBY
  end

  it "still flags the min or max of an array literal whose calls may answer nil" do
    expect_offense(<<~RUBY)
      class Patience
        def limit = [@seconds, @limits.first].max
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `limit` passes on the nil `max` can return; return a null object, or fail fast.
        def low = [@seconds, ceiling].min
                  ^^^^^^^^^^^^^^^^^^^^^^^ `low` passes on the nil `min` can return; return a null object, or fail fast.
        def least = [@seconds, size].min
                    ^^^^^^^^^^^^^^^^^^^^ `least` passes on the nil `min` can return; return a null object, or fail fast.
      end
    RUBY
  end

  # blueprinter's ViewCollection#[] and kimera's Pens#index (fp/twin-blueprinter-2, fp/kimera-2): the project's own
  # method answers, and its body never answers nil.
  it "allows a lookup's name that reaches the project's own method, which never answers nil" do
    expect_no_offenses(<<~RUBY)
      class Shelf
        def initialize
          @rows = {}
        end

        def [](label)
          @rows[label] ||= Row.new(label)
        end

        def first = self[:first]
        def index = @rows.to_h { |label, row| [row, label] }
        def top = index.size
      end

      class Form
        def pens = Pens.new(@nodes).index
        def shelf = shelved[:a]
        def kept = @shelf[:b]
        def shelved = @_shelved ||= Shelf.new

        def initialize
          @shelf = Shelf.new
        end

        def drawn
          shelf = Shelf.new
          shelf[:c]
        end
      end

      class Pens
        def index = @nodes.to_h { |node| [node, node.to_s] }
      end

      class Kinds
        def [](kind)
          return :none if kind.nil?
          case kind
          when :a then "a"
          else kind.to_s
          end
        end

        def first = @kinds.empty? ? "none" : @kinds.size.to_s
        def last
          begin
            @kinds.sort.join
          end
        end

        def kind = self[:a]
        def head = first
        def tail = last
        def pair = Pair.new.first
      end

      class Pair
        def first = return 1, 2
      end
    RUBY
  end

  it "still flags the project's own lookup that may answer nil, and one the receiver's class does not define" do
    expect_offense(<<~RUBY)
      class Shelf
        def [](label) = @rows[label]
        def index = @rows.index(@row)
        def last = @rows.last

        def first = self[:first]
                    ^^^^^^^^^^^^ `first` passes on the nil `[]` can return; return a null object, or fail fast.
        def tail = last
                   ^^^^ `tail` passes on the nil `last` can return; return a null object, or fail fast.
      end

      class Form
        def pens = Pens.new(@nodes).index
                   ^^^^^^^^^^^^^^^^^^^^^^ `pens` passes on the nil `index` can return; return a null object, or fail fast.
        def rows = Shelf.new.index
                   ^^^^^^^^^^^^^^^ `rows` passes on the nil `index` can return; return a null object, or fail fast.
        def any = @pens.index(@node)
                  ^^^^^^^^^^^^^^^^^^ `any` passes on the nil `index` can return; return a null object, or fail fast.

        def drawn(shelf)
          shelf = Shelf.new if shelf.nil?
          shelf[:c]
          ^^^^^^^^^ `drawn` passes on the nil `[]` can return; return a null object, or fail fast.
        end

        def self.top = first
                       ^^^^^ `top` passes on the nil `first` can return; return a null object, or fail fast.
        def first = @rows.first
      end

      class Pens
        def index(node) = @nodes.index(node)
      end

      # rufus-scheduler's JobArray#[]: the block's value is a `find`, which a call around it does not vouch for.
      class Jobs
        def [](id)
          @mutex.synchronize { @array.find { |job| job.id == id } }
        end

        def first
          return if @array.empty?
          @array.fetch(0)
        end

        def last
          return @array.fetch(-1) if @open
        end

        def job(id) = self[id]
                      ^^^^^^^^ `job` passes on the nil `[]` can return; return a null object, or fail fast.
        def head = first
                   ^^^^^ `head` passes on the nil `first` can return; return a null object, or fail fast.
        def tail = last
                   ^^^^ `tail` passes on the nil `last` can return; return a null object, or fail fast.
      end

      class Rows
        def last
          return @rows.last if @open
          "none"
        end

        def first
          return if @rows.empty?
          "some"
        end

        def tail = last
                   ^^^^ `tail` passes on the nil `last` can return; return a null object, or fail fast.
        def head = first
                   ^^^^^ `head` passes on the nil `first` can return; return a null object, or fail fast.
      end

      class Store
        def [](key) = @rows[key] ||= key.to_s

        def pick(store)
          store = Store.new if store.nil?
          store[:a]
          ^^^^^^^^^ `pick` passes on the nil `[]` can return; return a null object, or fail fast.
        end
      end

      class Kinds
        def [](kind)
          case kind
          when :a then "a"
          end
        end

        def sample = @kinds.size > 1 ? @kinds.fetch(1) : "none"

        def kind = self[:a]
                   ^^^^^^^^ `kind` passes on the nil `[]` can return; return a null object, or fail fast.
        def pick = sample
                   ^^^^^^ `pick` passes on the nil `sample` can return; return a null object, or fail fast.
      end
    RUBY
  end

  # timecop's Destination#instant (fp/twin-timecop-1): the value is returned only when it is a Time.
  it "allows a lookup returned under a type guard that rules nil out" do
    expect_no_offenses(<<~RUBY)
      class Pick
        def time
          return first if first.is_a?(Time)
          Time.at(Integer(first))
        end

        def stamp = (first if @open && first.kind_of?(Numeric)) || 0

        def mark
          return first if @open && first.kind_of?(Numeric)
          0
        end

        def zone
          if first.instance_of?(String)
            first
          else
            "UTC"
          end
        end

        private

        def first = @arguments.first
      end
    RUBY
  end

  it "still flags a lookup returned under a guard that lets nil through" do
    expect_offense(<<~RUBY)
      class Pick
        def time
          return first if first.is_a?(Object)
                 ^^^^^ `time` passes on the nil `first` can return; return a null object, or fail fast.
          return first unless first.is_a?(Time)
                 ^^^^^ `time` passes on the nil `first` can return; return a null object, or fail fast.
          return first if @rows.is_a?(Time)
                 ^^^^^ `time` passes on the nil `first` can return; return a null object, or fail fast.
          return first if first.is_a?(Time) || @open
                 ^^^^^ `time` passes on the nil `first` can return; return a null object, or fail fast.
          return first if first.respond_to?(:to_time)
                 ^^^^^ `time` passes on the nil `first` can return; return a null object, or fail fast.
          Time.at(Integer(first))
        end

        def zone
          if first.is_a?(NilClass)
            first
            ^^^^^ `zone` passes on the nil `first` can return; return a null object, or fail fast.
          else
            "UTC"
          end
        end

        private

        def first = @arguments.first
      end
    RUBY
  end

  context "with the project's files" do
    include ProjectFiles

    let(:setting) { { "Kata/NoNilReturn" => cop_config.merge("OwnedPaths" => ["lib/**/*.rb"]) } }

    it "follows a receiver to its class in another file" do
      files = {
        "lib/scribe/pens.rb" => "module Scribe\n  class Pens\n    def index = @nodes.to_h { [it, 1] }\n  end\nend\n",
        "lib/scribe/marks.rb" => "module Scribe\n  class Marks\n    def index = @nodes.index(@node)\n  end\nend\n",
        "lib/scribe/form.rb" => <<~RUBY
          module Scribe
            class Form
              def pens = Pens.new(@nodes).index
              def marks = Marks.new(@nodes).index
            end
          end
        RUBY
      }
      found = project_offenses(files, "lib/scribe/form.rb")
      expect(found.map { [it.line, it.message] })
        .to(eq([[4, "`marks` passes on the nil `index` can return; return a null object, or fail fast."]]))
    end
  end
end
