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

    it "allows the object's own empty buffer and identity table" do
      expect_no_offenses(<<~RUBY)
        def initialize(names)
          @text = +""
          @frozen = -"sep"
          @seen = {}.compare_by_identity
          @memo = Hash.new { |hash, key| hash[key] = key.to_s }.compare_by_identity
          @names = names
          compare_by_identity
        end
      RUBY
    end

    it "still flags a buffer built from what was passed in" do
      expect_offense(<<~RUBY)
        def initialize(name, table)
          @text = +name
                  ^^^^^ A constructor assigns; it does not compute. Move `+@` out of `initialize`.
          @seen = table.compare_by_identity
                  ^^^^^^^^^^^^^^^^^^^^^^^^^ A constructor assigns; it does not compute. Move `compare_by_identity` out of `initialize`.
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

  context "with a project's raising helper" do
    let(:cop_config) { { "RaisingMethods" => %w[raise user_error!] } }

    it "allows a guard that raises through it" do
      expect_no_offenses(<<~RUBY)
        def initialize(path)
          UI.user_error!("missing \#{path.inspect}") unless File.exist?(path)
          @path = path
        end
      RUBY
    end

    it "still flags a guard whose branch only logs" do
      expect_offense(<<~RUBY)
        def initialize(path)
          UI.important("missing") unless path
          ^^^^^^^^^^^^^^^^^^^^^^^ A constructor assigns; it does not compute. Move `important` out of `initialize`.
          @path = path
        end
      RUBY
    end
  end

  it "reads only initialize" do
    expect_no_offenses(<<~RUBY)
      def build(items)
        @total = items.sum
      end
    RUBY
  end
end
