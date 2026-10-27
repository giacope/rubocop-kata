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

  # rubytoolbox's `self.project = project`: assigning through the class's own writer, which Kata/NoSetter reports.
  it "reads an assignment through the object's own writer as assignment" do
    expect_offense(<<~RUBY)
      def initialize(project, checks)
        self.project = project
        self.checks = checks.map(&:to_s)
                      ^^^^^^^^^^^^^^^^^^ A constructor assigns; it does not compute. Move `map`, `validate!` and `owner=` out of `initialize`.
        self.validate!
        project.owner = self
      end
    RUBY
  end

  it "still flags a store into the object itself" do
    expect_offense(<<~RUBY)
      def initialize(name)
        self[:name] = name
        ^^^^^^^^^^^^^^^^^^ A constructor assigns; it does not compute. Move `[]=` out of `initialize`.
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
           ^^^^^^^^^^^ A constructor assigns; it does not compute. Move `empty?`, `ready?` and `done?` out of `initialize`.
          raise ArgumentError
        else
          @name = name
        end
        @ready = true if name.ready?
        if name.done?
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
                 ^^^^^^^^ A constructor assigns; it does not compute. Move `map` and `name` out of `initialize`.
      end
    RUBY
  end

  # opal's CLIOptions#initialize: two hundred `on` calls are one decision.
  it "reports a constructor once, counting each call it would move" do
    expect_offense(<<~RUBY)
      def initialize(record)
        @message = "\#{record.name} \#{record.name} \#{record.name}"
                      ^^^^^^^^^^^ A constructor assigns; it does not compute. Move `name` ×3 out of `initialize`.
      end
    RUBY
  end

  it "reads an empty constructor" do
    expect_no_offenses("def initialize; end\n")
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
                  ^^^^^ A constructor assigns; it does not compute. Move `+@` and `compare_by_identity` out of `initialize`.
          @seen = table.compare_by_identity
        end
      RUBY
    end

    it "still flags a hidden dependency or a computation" do
      expect_offense(<<~RUBY)
        def initialize(items, url)
          @id = SecureRandom.uuid
                ^^^^^^^^^^^^^^^^^ A constructor assigns; it does not compute. Move `uuid`, `new`, `sum`, `map` and `instance_method` out of `initialize`.
          @client = Http::Client.new(url)
          @total = items.sum
          @ids = Set.new(items.map(&:id))
          @size = String.instance_method(:size)
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

  it "leaves a parameter default, the seam a dependency comes in through" do
    expect_no_offenses(<<~RUBY)
      def initialize(items, shelf: Dir.tmpdir, id: SecureRandom.uuid)
        @items = items
        @shelf = shelf
        @id = id
      end
    RUBY
  end

  it "reads only initialize" do
    expect_no_offenses(<<~RUBY)
      def build(items)
        @total = items.sum
      end
    RUBY
  end

  context "with Sorbet" do
    let(:cop_config) { { "Sorbet" => true } }

    it "reads a T.let as the value it declares, and type expressions as types" do
      expect_offense(<<~RUBY)
        def initialize(token, hosts, client)
          @client = T.let(client, Dependabot::Clients::Bitbucket)
          @token = T.let(token, T.nilable(String))
          @hosts = T.let(hosts, T::Array[String])
          @lines = T.let(@io.readlines, T::Array[String])
                         ^^^^^^^^^^^^^ A constructor assigns; it does not compute. Move `readlines` out of `initialize`.
        end
      RUBY
    end
  end

  it "reads T.let as a call where the project does not use Sorbet" do
    expect_offense(<<~RUBY)
      def initialize(token)
        @token = T.let(token, String)
                 ^^^^^^^^^^^^^^^^^^^^ A constructor assigns; it does not compute. Move `let` out of `initialize`.
      end
    RUBY
  end

  context "with several ways to build" do
    let(:ruby_version) { 3.4 }
    let(:cop_config) { { "RaisingMethods" => %w[raise], "CheckPaths" => true } }
    let(:paths) { "several constructors in one. #{primary}" }
    let(:primary) { "Keep one primary constructor, and give each other way a class method that calls `new`." }

    it "flags a constructor that branches on its arguments, once" do
      expect_offense(<<~RUBY)
        class Money
          def initialize(cents = 0, currency = "USD", formatted: nil)
            if formatted
            ^^ `initialize` picks a way to build itself from `formatted` and `currency`: #{paths}
              @cents = formatted
            else
              @cents = cents
            end
            @currency = currency unless currency
          end
        end
      RUBY
    end

    it "flags a case on an argument" do
      expect_offense(<<~RUBY)
        class Money
          def initialize(*parts)
            case parts
            ^^^^ `initialize` picks a way to build itself from `parts`: #{paths}
            when [] then @cents = 0
            end
          end
        end
      RUBY
    end

    it "flags a class method that builds past initialize" do
      expect_offense(<<~RUBY)
        class Money
          def self.from_hash(hash)
            money = allocate
                    ^^^^^^^^ `allocate` builds an instance past `initialize`, a second primary constructor; call `new` instead.
            money
          end

          class << self
            def blank = self.allocate
                        ^^^^^^^^^^^^^ `allocate` builds an instance past `initialize`, a second primary constructor; call `new` instead.
          end
        end
      RUBY
    end

    it "allows a guard that raises, a branch on its own state, and allocate elsewhere" do
      expect_no_offenses(<<~RUBY)
        class Money
          def initialize(cents)
            raise ArgumentError, "negative" if cents
            @cents = cents
            @ready = true if READY
            case
            when READY then @mode = 1
            end
          end

          def copy = Other.allocate
          def own = allocate
        end
        allocate
      RUBY
    end

    it "reads one way to build without CheckPaths, as kata ships it" do
      cop_config.delete("CheckPaths")
      expect_no_offenses(<<~RUBY)
        class Money
          def initialize(cents, formatted: false)
            @cents = formatted ? cents : cents
            if formatted
              @label = cents
            end
          end

          def self.load(row) = allocate
        end
      RUBY
    end
  end
end
