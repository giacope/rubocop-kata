# frozen_string_literal: true

require "tmpdir"

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

  it "allows the helpers a constructor calls in a class built by a block" do
    expect_no_offenses(<<~RUBY)
      Account = Class.new do
        def initialize = prepare

        def prepare = fill

        def fill = @balance = 0
      end
    RUBY
  end

  it "flags a method that sets state in a class built by a block, when no constructor calls it" do
    expect_offense(<<~RUBY)
      Account = Class.new do
        def initialize = prepare

        def prepare = @ready = true

        def reset = @ready = false
                    ^^^^^^ `@ready` changes after construction; set state once in `initialize` and return a new object to change it.
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

  context "with the content of an instance variable" do
    let(:other_cops) { { "Kata/NoOutputArgument" => { "MutatingMethods" => %w[<< []= push delete] } } }

    it "flags changing what an instance variable holds after construction" do
      expect_offense(<<~RUBY)
        class Basket
          def initialize
            @items = []
            @items << :seed
          end

          def add(item)
            @items << item
            ^^^^^^^^^^^^^^ `@items` changes after construction; set state once in `initialize` and return a new object to change it.
            @index[item] = true
            ^^^^^^^^^^^^^^^^^^^ `@index` changes after construction; set state once in `initialize` and return a new object to change it.
          end

          def fetch(key) = @cache[key] ||= key.to_s

          def remember(key)
            @index[key] = true unless @index.key?(key)
            @index[key] = false unless @cache.key?(key)
            ^^^^^^^^^^^^^^^^^^^ `@index` changes after construction; set state once in `initialize` and return a new object to change it.
            @index[key] = nil unless @index.frozen?
            ^^^^^^^^^^^^^^^^^ `@index` changes after construction; set state once in `initialize` and return a new object to change it.
          end
          def count = @items.size
          def drop(item) = @items.delete(item).then { @items }
                           ^^^^^^^^^^^^^^^^^^^ `@items` changes after construction; set state once in `initialize` and return a new object to change it.
        end
      RUBY
    end
  end

  context "with Sorbet" do
    let(:cop_config) { { "Sorbet" => true } }

    it "reads a T.let of the variable itself as its declaration, not a change" do
      expect_offense(<<~RUBY)
        class Client
          def token
            @token = T.let(@token, T.nilable(String))
            @token ||= fetch
          end

          def reset = @token = T.let(nil, T.nilable(String))
                      ^^^^^^ `@token` changes after construction; set state once in `initialize` and return a new object to change it.
          def again = @token = @token
                      ^^^^^^ `@token` changes after construction; set state once in `initialize` and return a new object to change it.
          def limit = @limit = T::Limit
                      ^^^^^^ `@limit` changes after construction; set state once in `initialize` and return a new object to change it.
        end
      RUBY
    end
  end

  context "with an Arbre component" do
    let(:cop_config) { { "ConstructorHooks" => ["Arbre#build"] } }

    it "takes build for construction only in a class descending from Arbre" do
      expect_offense(<<~RUBY)
        module Admin
          class Component < Arbre::Component
          end

          class Panel < Component
            def build(title) = @title = title
          end

          class Report
            def build(title) = @title = title
                               ^^^^^^ `@title` changes after construction; set state once in `initialize` and return a new object to change it.
          end

          Widget = Class.new(Arbre::Component) do
            def build(title) = @title = title
                               ^^^^^^ `@title` changes after construction; set state once in `initialize` and return a new object to change it.
          end
        end
      RUBY
    end
  end

  context "with the project's other files" do
    include TabledCop

    let(:root) { Dir.mktmpdir("kata-frozen") }
    let(:cop) do
      shipped = { "Kata/FrozenState" => { "OwnedPaths" => ["lib/**/*.rb"] } }
      described_class.new(RuboCop::Config.new(shipped, File.join(root, ".rubocop.yml")))
    end

    before do
      FileUtils.mkdir_p(File.join(root, "lib"))
      switching = "module Shelf\n  module Switching\n    def parse_with_mode(markup) = [strict_parse(markup), " \
        "@log.lax_parse(markup)]\n  end\nend\n"
      tag = "module Shelf\n  class Tag\n    include Switching\n\n    " \
        "def initialize(markup) = parse_with_mode(markup)\n  end\nend\n"
      File.write(File.join(root, "lib", "switching.rb"), switching)
      File.write(File.join(root, "lib", "tag.rb"), tag)
    end

    after { FileUtils.rm_rf(root) }

    it "follows a constructor helper through a mixin and a superclass in other files" do
      source = <<~RUBY
        module Shelf
          class If < ::Shelf::Tag
            def strict_parse(markup) = @markup = markup
            def render = @rendered = true
            def lax_parse(markup) = @lax = markup
          end
        end
      RUBY
      expect(offenses(source).map(&:line)).to(eq([4, 5]))
    end
  end

  context "without Sorbet" do
    it "reads a T.let of the variable itself as an assignment" do
      expect_offense(<<~RUBY)
        class Client
          def token = @token = T.let(@token, T.nilable(String))
                      ^^^^^^ `@token` changes after construction; set state once in `initialize` and return a new object to change it.
        end
      RUBY
    end
  end

  context "with a hook a framework calls inside a block-built class" do
    let(:cop_config) { { "ConstructorHooks" => ["setup"] } }

    it "takes the hook for construction" do
      expect_no_offenses(<<~RUBY)
        Point = Struct.new(:x) do
          def setup = @ready = true
        end
      RUBY
    end
  end

  # doorkeeper's `module ClassMethods`, roda's RequestClassMethods, rom's ClassInterface.
  it "leaves class-side state to ThreadSafety where it reports it, and says it is class state elsewhere" do
    expect_offense(<<~RUBY)
      module Naming
        module ClassMethods
          def table(name) = @table = name
        end
        concern = proc do
          class_methods do
            def column(name) = @column = name
          end
        end
        module Tools
          module_function

          def tool(name) = @tool = name
        end
        module RequestClassMethods
          def match(name) = @match = name
                            ^^^^^^ `@match` is class-level state every caller shares, changed after load; set it once and freeze it, or keep it in an object the class holds.
        end
        module Helpers
          extend self

          def cache(name) = @cache = name
                            ^^^^^^ `@cache` is class-level state every caller shares, changed after load; set it once and freeze it, or keep it in an object the class holds.
        end
        module ClassInterface
          def schema(name) = @schema = name
                             ^^^^^^^ `@schema` is class-level state every caller shares, changed after load; set it once and freeze it, or keep it in an object the class holds.
        end
        module Plain
          def plain(name) = @plain = name
                            ^^^^^^ `@plain` is class-level state every caller shares, changed after load; set it once and freeze it, or keep it in an object the class holds.
        end
        module Mixed
          def mixed(name) = @mixed = name
                            ^^^^^^ `@mixed` changes after construction; set state once in `initialize` and return a new object to change it.
        end
        Store.extend(Plain)
      end
    RUBY
  end
end
