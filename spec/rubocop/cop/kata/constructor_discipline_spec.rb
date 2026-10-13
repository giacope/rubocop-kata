# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::ConstructorDiscipline, :config) do
  it "flags computation inside initialize" do
    expect_offense(<<~RUBY)
      def initialize(io)
        @lines = io.readlines
                 ^^^^^^^^^^^^ A constructor assigns; it does not compute. Move `readlines` out of `initialize`.
      end
    RUBY
  end

  it "flags a safe-navigation call as computation too" do
    expect_offense(<<~RUBY)
      def initialize(name)
        @name = name&.strip
                ^^^^^^^^^^^ A constructor assigns; it does not compute. Move `strip` out of `initialize`.
      end
    RUBY
  end

  it "allows assignment, raising, and freezing" do
    expect_no_offenses(<<~RUBY)
      def initialize(io)
        raise ArgumentError unless io
        @io = io
        freeze
      end
    RUBY
  end

  it "allows the guard and the message of a raise" do
    expect_no_offenses(<<~RUBY)
      def initialize(name)
        raise ArgumentError, "bad \#{name.inspect}" unless name.is_a?(String)
        if name.empty?
          raise ArgumentError
        else
          raise TypeError
        end
        @name = name
      end
    RUBY
  end

  it "still flags a condition whose branches do more than raise" do
    expect_offense(<<~RUBY)
      def initialize(name)
        if name.empty?
           ^^^^^^^^^^^ A constructor assigns; it does not compute. Move `empty?` out of `initialize`.
          raise ArgumentError
        else
          @name = name
        end
        @ready = true if name.ready?
                         ^^^^^^^^^^^ A constructor assigns; it does not compute. Move `ready?` out of `initialize`.
        if name.done?
           ^^^^^^^^^^ A constructor assigns; it does not compute. Move `done?` out of `initialize`.
        end
      end
    RUBY
  end

  it "allows a lambda or proc, whose body runs later" do
    expect_no_offenses(<<~RUBY)
      def initialize(source)
        @stabby = -> { source.read }
        @lambda = lambda { source.read }
        @proc = proc { source.read }
        @numbered = -> { _1.read }
      end
    RUBY
  end

  it "flags a block that runs now" do
    expect_offense(<<~RUBY)
      def initialize(list)
        @names = list.map { |user| user.name }
                                   ^^^^^^^^^ A constructor assigns; it does not compute. Move `name` out of `initialize`.
                 ^^^^^^^^ A constructor assigns; it does not compute. Move `map` out of `initialize`.
      end
    RUBY
  end

  it "leaves computation in other methods alone" do
    expect_no_offenses(<<~RUBY)
      def build(io)
        @io = io.dup
      end
    RUBY
  end

  context "with the shipped defaults" do
    let(:cop_config) { RuboCop::ConfigLoader.default_configuration.for_cop("Kata/ConstructorDiscipline") }

    it "allows shaping what was passed in, and the object's own lock and collections" do
      expect_no_offenses(<<~RUBY)
        def initialize(items, name, port)
          @items = Array(items).dup.freeze
          @name = name.to_s
          @port = Integer(port)
          @lock = Mutex.new
          @queue = Thread::Queue.new
          @seen = Set.new
          @index = Hash.new { |hash, key| hash[key] = [] }
        end
      RUBY
    end

    it "still flags a hidden dependency or a computation" do
      expect_offense(<<~RUBY)
        def initialize(items, url)
          @id = SecureRandom.uuid
                ^^^^^^^^^^^^^^^^^ A constructor assigns; it does not compute. Move `uuid` out of `initialize`.
          @client = Http::Client.new(url)
                    ^^^^^^^^^^^^^^^^^^^^^ A constructor assigns; it does not compute. Move `new` out of `initialize`.
          @total = items.sum
                   ^^^^^^^^^ A constructor assigns; it does not compute. Move `sum` out of `initialize`.
          @ids = Set.new(items.map(&:id))
                         ^^^^^^^^^^^^^^^ A constructor assigns; it does not compute. Move `map` out of `initialize`.
          @size = String.instance_method(:size)
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ A constructor assigns; it does not compute. Move `instance_method` out of `initialize`.
        end
      RUBY
    end
  end
end
