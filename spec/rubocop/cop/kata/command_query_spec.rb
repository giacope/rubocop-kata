# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::CommandQuery, :config) do
  let(:ruby_version) { 3.4 }

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
        rest.shift!
        ^^^^^^^^^^^ `ready?` asks a question and changes state with `shift!`; a query answers, a command acts.
        rows.flatten!
        ^^^^^^^^^^^^^ `ready?` asks a question and changes state with `flatten!`; a query answers, a command acts.
        record&.lock!
        ^^^^^^^^^^^^^ `ready?` asks a question and changes state with `lock!`; a query answers, a command acts.
        log(reload!)
            ^^^^^^^ `ready?` asks a question and changes state with `reload!`; a query answers, a command acts.
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
end
