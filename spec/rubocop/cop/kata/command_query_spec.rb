# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::CommandQuery, :config) do
  let(:ruby_version) { 3.4 }
  let(:cop_config) { { "CheckEveryQuery" => true } }

  it "flags a query that assigns state" do
    expect_offense(<<~RUBY)
      def valid?
        @checked = true
        ^^^^^^^^^^^^^^^ `valid?` asks a question and changes state with `@checked =`; a query answers, a command acts.
        @errors.empty?
      end
    RUBY
  end

  it "flags a query that calls a bang method on itself, its state, or its parameters" do
    expect_offense(<<~RUBY)
      def self.ready?(record, *rest, flag: nil)
        save!
        ^^^^^ `ready?` asks a question and changes state with `save!`; a query answers, a command acts.
        self.touch!
        ^^^^^^^^^^^ `ready?` asks a question and changes state with `touch!`; a query answers, a command acts.
        @rows.compact!
        ^^^^^^^^^^^^^^ `ready?` asks a question and changes state with `compact!`; a query answers, a command acts.
        @@rows.uniq!
        ^^^^^^^^^^^^ `ready?` asks a question and changes state with `uniq!`; a query answers, a command acts.
        $rows.sort!
        ^^^^^^^^^^^ `ready?` asks a question and changes state with `sort!`; a query answers, a command acts.
        Cache.clear!
        ^^^^^^^^^^^^ `ready?` asks a question and changes state with `clear!`; a query answers, a command acts.
        record.update!(seen: true)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^ `ready?` asks a question and changes state with `update!`; a query answers, a command acts.
        rows.flatten!
        ^^^^^^^^^^^^^ `ready?` asks a question and changes state with `flatten!`; a query answers, a command acts.
        record&.lock!
        ^^^^^^^^^^^^^ `ready?` asks a question and changes state with `lock!`; a query answers, a command acts.
        @rows.each { @cache.clear! }
                     ^^^^^^^^^^^^^ `ready?` asks a question and changes state with `clear!`; a query answers, a command acts.
        @rows.select! { it }
        ^^^^^^^^^^^^^ `ready?` asks a question and changes state with `select!`; a query answers, a command acts.
        begin
          @rows.sort!
          ^^^^^^^^^^^ `ready?` asks a question and changes state with `sort!`; a query answers, a command acts.
          true
        end
        flag && @rows.shuffle!
                ^^^^^^^^^^^^^^ `ready?` asks a question and changes state with `shuffle!`; a query answers, a command acts.
        flag || @name.squeeze!
                ^^^^^^^^^^^^^^ `ready?` asks a question and changes state with `squeeze!`; a query answers, a command acts.
        @name.strip! if flag
        ^^^^^^^^^^^^ `ready?` asks a question and changes state with `strip!`; a query answers, a command acts.
        case flag
        when 1 then @rows.reverse!
                    ^^^^^^^^^^^^^^ `ready?` asks a question and changes state with `reverse!`; a query answers, a command acts.
        end
        record.valid?
      end
    RUBY
  end

  # mechanize's `visited?` and `resolve`, ahoy's `group_prop(*props)`, collections-publisher's `I18n.t!`.
  it "reads a change to a copy or a splat as the method's own, and a bang whose value is used as a query" do
    expect_no_offenses(<<~RUBY)
      def visited?(uri, link, *props, **options)
        uri = uri.dup
        uri.path = "/" if uri.path.empty?
        uri.normalize!
        link = URI(link.to_s)
        link.host!
        props.flatten!
        options.compact!
        seen = [reload!]
        @index.include?(uri.to_s) && seen.any?
      end

      def rows?(url)
        rows = { "Status" => I18n.t!("statuses") }
        link = url ? secure_resolve!(url) : @home
        case url
        when String then resolve!(url)
        end.then { fetch!(url).to_s }
        found = url && resolve!(url)
        kept = begin
          resolve!(url)
        end
        @rows.uniq! || @rows
        @rows.compact! ? 1 : 2
        @rows.map { it }.first!
        names = @rows.map { @cache.fetch!(it) }
        rows.size > link.size + names.size
      end
    RUBY
  end

  it "flags a bang that is the query's own answer" do
    expect_offense(<<~RUBY)
      def verified?(code)
        return false unless code
        save!(validate: false)
        ^^^^^^^^^^^^^^^^^^^^^^ `verified?` asks a question and changes state with `save!`; a query answers, a command acts.
      end

      def ready? = Cache.ready!
                   ^^^^^^^^^^^^ `ready?` asks a question and changes state with `ready!`; a query answers, a command acts.

      def done?
        return @rows.compact! if @rows
               ^^^^^^^^^^^^^^ `done?` asks a question and changes state with `compact!`; a query answers, a command acts.
        @rows.any? { @cache.clear! }
                     ^^^^^^^^^^^^^ `done?` asks a question and changes state with `clear!`; a query answers, a command acts.
      end
    RUBY
  end

  it "allows a guard that raises through a bang on a constant" do
    expect_no_offenses(<<~RUBY)
      def specified?(key)
        Guard.reject!("key must be a symbol") unless key.is_a?(Symbol)
        UI.user_error!("no values") if @values.nil?
        @values.key?(key)
      end
    RUBY
  end

  # hashie's `_assert_property_exists!(property)`, which calls `_fail_no_property_error!`, which raises.
  it "allows a call to a method of the project that only raises, directly or through another" do
    expect_no_offenses(<<~RUBY)
      class Record
        def [](key)
          assert_known!(key)
          self.check!(key)
          @values.fetch(key)
        end

        def known?(key)
          assert_known!(key)
          check!(key)
          true
        end

        private

        def assert_known!(key)
          fail_unknown!(key) unless @fields.include?(key)
        end

        def fail_unknown!(key)
          message = "unknown field \#{key}"
          raise ArgumentError, message
        end

        def check!(key)
          if key.nil?
            raise ArgumentError, "no key"
          end
        end
      end
    RUBY
  end

  it "still flags a bang on itself that changes state too, or that another definition of its name does" do
    expect_offense(<<~RUBY)
      class Record
        def known?(key)
          load!(key)
          ^^^^^^^^^^ `known?` asks a question and changes state with `load!`; a query answers, a command acts.
          reset!
          ^^^^^^ `known?` asks a question and changes state with `reset!`; a query answers, a command acts.
          @store.assert!(key)
          ^^^^^^^^^^^^^^^^^^^ `known?` asks a question and changes state with `assert!`; a query answers, a command acts.
          guard!(key)
          ^^^^^^^^^^^ `known?` asks a question and changes state with `guard!`; a query answers, a command acts.
          close!
          ^^^^^^ `known?` asks a question and changes state with `close!`; a query answers, a command acts.
          spin!(key)
          ^^^^^^^^^^ `known?` asks a question and changes state with `spin!`; a query answers, a command acts.
          true
        end

        private

        def load!(key)
          raise ArgumentError, "no key" unless key
          @values[key] = @loader.call(key)
        end

        def reset!
          raise "closed" if @closed
        end

        def assert!(key) = raise(ArgumentError, key)

        def close!
          @closed = true
          raise "closed"
        end

        def spin!(key) = turn!(key)

        def turn!(key) = spin!(key)

        def guard!(key)
          raise ArgumentError, "no key" unless key
        rescue ArgumentError
          @errors << key
        end
      end

      class Cache
        def reset! = @rows.clear
      end
    RUBY
  end

  context "with the project's other files" do
    include TabledCop

    let(:root) { Dir.mktmpdir("kata-raising") }
    let(:cop) do
      shipped = RuboCop::ConfigLoader.default_configuration.for_cop("Kata/CommandQuery")
      raising = { "Kata/CommandQuery" => shipped.merge("OwnedPaths" => ["lib/**/*.rb"]) }
      described_class.new(RuboCop::Config.new(raising, File.join(root, ".rubocop.yml")))
    end

    before do
      FileUtils.mkdir_p(File.join(root, "lib"))
      dash = "class Dash\n  def assert_exists!(key)\n    fail_missing!(key) unless key?(key)\n  end\n\n  " \
        "def fail_missing!(key)\n    raise NoMethodError, key.to_s\n  end\n\n  def touch!(key) = @seen << key\nend\n"
      File.write(File.join(root, "lib", "dash.rb"), dash)
    end

    after { FileUtils.rm_rf(root) }

    it "reads a method another file defines to raise as raising" do
      translation = "module Translation\n  def exists?(key)\n    assert_exists!(key)\n    true\n  end\nend\n"
      other = "module Translation\n  def exists?(key)\n    fail_other!(key)\n    touch!(key)\n    true\n  end\nend\n"
      expect([offenses(translation), offenses(other).map(&:line)]).to(eq([[], [3, 4]]))
    end
  end

  it "still flags a bang on a constant that is not a guard's only branch" do
    expect_offense(<<~RUBY)
      def stale?
        if expired?
          Cache.clear!
          ^^^^^^^^^^^^ `stale?` asks a question and changes state with `clear!`; a query answers, a command acts.
          true
        end
      end
    RUBY
  end

  it "allows memoizing the answer" do
    expect_no_offenses(<<~RUBY)
      def valid?
        @valid ||= errors.empty?
      end

      def ready?
        return @ready if defined?(@ready)
        @ready = check
      end
    RUBY
  end

  it "allows a bang call whose answer the query reads, and changes to its own locals" do
    expect_no_offenses(<<~RUBY)
      def show?
        policy!(user, record).show?
        found = fetch!(record)
        names = record.names.dup
        names.compact!
        rows(1).sort!
        !found
      end
    RUBY
  end

  it "leaves commands and plain methods alone" do
    expect_no_offenses(<<~RUBY)
      def validate!
        @checked = true
        save!
      end

      def check
        @checked = true
      end

      def empty?; end
    RUBY
  end

  context "with a method that answers with a value" do
    let(:advice) { "a query answers, a command acts. Split them, or return a new object instead of acting." }

    it "flags a command whose value the query throws away" do
      expect_offense(<<~RUBY)
        def balance
          @audit.record("balance read")
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `balance` answers with a value and acts with `record`; #{advice}
          @entries.sum
        end

        def withdraw(cents)
          Rails.logger.info("withdrawal") if cents.positive?
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `withdraw` answers with a value and acts with `info`; #{advice}
          touch
          ^^^^^ `withdraw` answers with a value and acts with `touch`; #{advice}
          cents.save
          ^^^^^^^^^^ `withdraw` answers with a value and acts with `save`; #{advice}
          notify(cents)
          ^^^^^^^^^^^^^ `withdraw` answers with a value and acts with `notify`; #{advice}
          @entries.sum - cents
        end

        def total
          if @audited
            @audit.record("total read")
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^ `total` answers with a value and acts with `record`; #{advice}
            @log.info("total")
            ^^^^^^^^^^^^^^^^^^ `total` answers with a value and acts with `info`; #{advice}
          end
          @entries.sum
        end
      RUBY
    end

    it "flags a state change and a bang on its state" do
      expect_offense(<<~RUBY)
        def label
          @seen = true
          ^^^^^^^^^^^^ `label` answers with a value and acts with `@seen =`; #{advice}
          @rows.compact!
          ^^^^^^^^^^^^^^ `label` answers with a value and acts with `compact!`; #{advice}
          "\#{@name}"
        end
      RUBY
    end

    it "flags a predicate that acts through a discarded message" do
      expect_offense(<<~RUBY)
        def empty?
          @audit.record("asked")
          ^^^^^^^^^^^^^^^^^^^^^^ `empty?` asks a question and changes state with `record`; a query answers, a command acts.
          @items.empty?
        end
      RUBY
    end

    it "allows building the method's own locals, guards, queries and iterations" do
      expect_no_offenses(<<~RUBY)
        def summary
          lines = []
          lines << @name
          decorate(lines)
          Format.pad(lines, 2)
          raise ArgumentError, "empty" if @name.empty?
          fail "no" unless @ready
          @rows.each { |row| lines << row }
          valid?
          @rows.size
          lines.join
        end

        def total
          @total ||= @rows.sum
        end
      RUBY
    end

    it "leaves commands, chained commands, constructors and writers alone" do
      expect_no_offenses(<<~RUBY)
        def ship
          @audit.record("shipped")
          @mailer.deliver(@order)
        end

        def add(item)
          @audit.record(item)
          self
        end

        def initialize(rows)
          @rows = rows
          log(rows)
          @rows.size
        end

        def save!
          @audit.record("saved")
          true
        end

        def name=(value)
          @audit.record(value)
          value
        end

        def plain = @rows.size
        def single
          @rows.size
        end
      RUBY
    end
  end

  context "without CheckEveryQuery, as kata ships it" do
    let(:cop_config) { {} }

    it "judges the `?` methods only, by the state they change" do
      expect_offense(<<~RUBY)
        def empty?
          @audit.record("asked")
          @count = 1
          ^^^^^^^^^^ `empty?` asks a question and changes state with `@count =`; a query answers, a command acts.
          @items.empty?
        end

        def balance
          @audit.record("balance read")
          @entries.sum
        end
      RUBY
    end
  end
end
