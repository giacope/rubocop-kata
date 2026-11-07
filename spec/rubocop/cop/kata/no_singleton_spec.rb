# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::NoSingleton, :config) do
  let(:ruby_version) { 3.4 }

  let(:cop_config) { { "AllowedConstructors" => %w[Set Struct], "CheckGlobals" => true } }

  it "flags the Singleton mixin" do
    expect_offense(<<~RUBY)
      class Registry
        include Singleton
        ^^^^^^^^^^^^^^^^^ `include Singleton` makes one global instance; build the object where it is needed and pass it in.
        include ::Singleton
        ^^^^^^^^^^^^^^^^^^^ `include Singleton` makes one global instance; build the object where it is needed and pass it in.
      end
    RUBY
  end

  it "allows other mixins" do
    expect_no_offenses(<<~RUBY)
      class Registry
        include Comparable
        include Billing::Singleton
        Other.include Singleton
      end
    RUBY
  end

  it "flags a class method caching an instance" do
    expect_offense(<<~RUBY)
      class Registry
        def self.instance
          @instance ||= load
          ^^^^^^^^^^^^^^^^^^ `@instance ||=` keeps one global instance on the class; build the object where it is needed and pass it in.
        end

        def self.client = @client ||= Http::Client.new(timeout: 3)
                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `@client ||=` keeps one global instance on the class; build the object where it is needed and pass it in.

        class << self
          def default
            @default ||= new.freeze
            ^^^^^^^^^^^^^^^^^^^^^^^ `@default ||=` keeps one global instance on the class; build the object where it is needed and pass it in.
          end
        end
      end
    RUBY
  end

  it "flags a class variable caching an instance, wherever it is" do
    expect_offense(<<~RUBY)
      class Registry
        def connection
          @@connection ||= self.new
          ^^^^^^^^^^^^^^^^^^^^^^^^^ `@@connection ||=` keeps one global instance on the class; build the object where it is needed and pass it in.
        end
      end
    RUBY
  end

  it "reads what the cache holds, not each object built on the way to it" do
    expect_offense(<<~RUBY)
      class Registry
        def self.all = @all ||= Codelist.new(type: "regions").map { new(it) }
        def self.mapping = @mapping ||= YAML.load(ERB.new(File.read(PATH)).result)
        def self.handler = @handler ||= lambda { |key| Handler.new(key) }
        def self.defaults = @defaults ||= { client: Client.new }
        def self.warmed = @warmed ||= tap { warm }

        def self.store
          @store ||= begin
          ^^^^^^^^^^^^^^^^ `@store ||=` keeps one global instance on the class; build the object where it is needed and pass it in.
            warm
            Store.new.tap(&:load)
          end
        end

        def self.cache = @cache ||= (Cache.new unless off?)
                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `@cache ||=` keeps one global instance on the class; build the object where it is needed and pass it in.
        def self.engine = @engine ||= ready? ? Engine.new : nil
                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `@engine ||=` keeps one global instance on the class; build the object where it is needed and pass it in.
        def self.logger = @logger ||= cached || Logger.new(STDOUT) { |line| line }
                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `@logger ||=` keeps one global instance on the class; build the object where it is needed and pass it in.
        def self.parser = @parser ||= case format when :json then Json.new end
                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `@parser ||=` keeps one global instance on the class; build the object where it is needed and pass it in.
      end
    RUBY
  end

  it "allows a class-level cache of a value, and instance memoization" do
    expect_no_offenses(<<~RUBY)
      class Registry
        def self.members = @members ||= Set.new(list)
        def self.row = @row ||= Struct.new(:a, :b)
        def self.names = @names ||= list.map(&:name)
        def self.reset = @client = Client.new
        def client = @client ||= Client.new
        @@count ||= 0
        @@total = Client.new

        class << self
          @shared ||= Client.new
        end
      end
    RUBY
  end

  it "flags a class that keeps request state in ActiveSupport::CurrentAttributes" do
    expect_offense(<<~RUBY)
      module Shop
        class Current < ActiveSupport::CurrentAttributes
                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `Current` is a global with a class name, reset per request; pass what it holds to what needs it.
          attribute :account, :user
        end

        class Session < ::ActiveSupport::CurrentAttributes
                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `Session` is a global with a class name, reset per request; pass what it holds to what needs it.
        end
      end
    RUBY
  end

  it "allows other superclasses" do
    expect_no_offenses(<<~RUBY)
      class Ledger < ApplicationRecord
      end

      class Attributes < CurrentAttributes
      end

      class Plain
      end
    RUBY
  end

  it "flags state kept in the thread, the fiber or the request store" do
    expect_offense(<<~RUBY)
      class Lottery
        def user
          Thread.current[:user]
          ^^^^^^^^^^^^^^^^^^^^^ `Thread.current[:user]` is global state keyed by the thread; pass the value to what needs it.
          ::Thread.current[:user] = @user
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `::Thread.current[:user]` is global state keyed by the thread; pass the value to what needs it.
          Thread.current.thread_variable_get(:state)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `Thread.current.thread_variable_get` is global state keyed by the thread; pass the value to what needs it.
          Fiber[:state] = 1
          ^^^^^^^^^^^^^^^^^ `Fiber[:state]` is global state keyed by the fiber; pass the value to what needs it.
          RequestStore.store[:user]
          ^^^^^^^^^^^^^^^^^^^^^^^^^ `RequestStore.store[:user]` is global state keyed by the thread; pass the value to what needs it.
          RequestStore[:user]
          ^^^^^^^^^^^^^^^^^^^ `RequestStore[:user]` is global state keyed by the thread; pass the value to what needs it.
        end
      end
    RUBY
  end

  it "allows asking the thread about itself, and the boot layer" do
    expect_no_offenses(<<~RUBY)
      Thread.current[:boot] = true

      class Worker
        def name = Thread.current.name
        def main? = Thread.current == Thread.main
        def other = @registry[:user]
        def defaults(user = Thread.current[:user]) = user
      end
    RUBY
  end

  it "allows a thread or fiber slot every write of which saves, sets, yields and restores it in an ensure" do
    expect_no_offenses(<<~RUBY)
      class Overrides
        SLOT = :overrides

        class Skipping
          def include?(name)
            held, names = Thread.current[SLOT]
            held.equal?(@klass) && names.include?(name)
          end
        end

        def skipping(names)
          previous = Thread.current[SLOT]
          Thread.current[SLOT] = [@klass, names]
          yield
        ensure
          Thread.current[SLOT] = previous
        end

        def locale = Fiber[:locale]

        def with_locale(locale)
          begin
            was = Fiber[:locale]
            Fiber[:locale] = locale
            yield
          ensure
            Fiber[:locale] = was
          end
        end
      end
    RUBY
  end

  it "allows the scope to name the thread once, as a local bound to Thread.current alone" do
    expect_no_offenses(<<~RUBY)
      class Overrides
        def skipped?(name) = Thread.current[:skipping].include?(name)

        def skipping(names)
          thread = Thread.current
          previous = thread[:skipping]
          thread[:skipping] = names
          yield
        ensure
          thread[:skipping] = previous
        end

        def spawned(work)
          thread = Thread.new(&work)
          thread.join
        end
      end
    RUBY
  end

  it "still flags a scope that restores the slot from a local saved off another one" do
    expect_offense(<<~RUBY)
      class Overrides
        def skipped?(name) = Thread.current[:skipping].include?(name)
                             ^^^^^^^^^^^^^^^^^^^^^^^^^ `Thread.current[:skipping]` is global state keyed by the thread; pass the value to what needs it.

        def skipping(names)
          previous = Thread.current[:held]
                     ^^^^^^^^^^^^^^^^^^^^^ `Thread.current[:held]` is global state keyed by the thread; pass the value to what needs it.
          Thread.current[:skipping] = names
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `Thread.current[:skipping]` is global state keyed by the thread; pass the value to what needs it.
          yield
        ensure
          Thread.current[:skipping] = previous
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `Thread.current[:skipping]` is global state keyed by the thread; pass the value to what needs it.
        end
      end
    RUBY
  end

  it "still flags a slot written through a local bound to anything but Thread.current" do
    expect_offense(<<~RUBY)
      class Overrides
        def skipped?(name) = Thread.current[:skipping].include?(name)
                             ^^^^^^^^^^^^^^^^^^^^^^^^^ `Thread.current[:skipping]` is global state keyed by the thread; pass the value to what needs it.

        def skipping(names, other)
          thread = Thread.current
          thread = other if other
          previous = thread[:skipping]
          thread[:skipping] = names
          yield
        ensure
          thread[:skipping] = previous
        end
      end
    RUBY
  end

  it "still flags a slot written unscoped anywhere in the file, or not written in it" do
    expect_offense(<<~RUBY)
      class Overrides
        def user = Thread.current[:user]
                   ^^^^^^^^^^^^^^^^^^^^^ `Thread.current[:user]` is global state keyed by the thread; pass the value to what needs it.

        def as(user)
          previous = Thread.current[:user]
                     ^^^^^^^^^^^^^^^^^^^^^ `Thread.current[:user]` is global state keyed by the thread; pass the value to what needs it.
          Thread.current[:user] = user
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `Thread.current[:user]` is global state keyed by the thread; pass the value to what needs it.
          yield
        ensure
          Thread.current[:user] = previous
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `Thread.current[:user]` is global state keyed by the thread; pass the value to what needs it.
        end

        def login(user)
          Thread.current[:user] = user
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `Thread.current[:user]` is global state keyed by the thread; pass the value to what needs it.
        end

        def account = Thread.current[:account]
                      ^^^^^^^^^^^^^^^^^^^^^^^^ `Thread.current[:account]` is global state keyed by the thread; pass the value to what needs it.

        def tenant = Fiber[:tenant]
                     ^^^^^^^^^^^^^^ `Fiber[:tenant]` is global state keyed by the fiber; pass the value to what needs it.

        def as_tenant(tenant)
          Fiber[:tenant] = tenant
          ^^^^^^^^^^^^^^^^^^^^^^^ `Fiber[:tenant]` is global state keyed by the fiber; pass the value to what needs it.
          yield
        ensure
          Fiber.current.storage.clear
          Thread.current.delete(:tenant)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `Thread.current.delete` is global state keyed by the thread; pass the value to what needs it.
        end
      end
    RUBY
  end

  it "still flags a slot whose scope saves, sets, yields or restores nothing" do
    message = "`Thread.current[:%s]` is global state keyed by the thread; pass the value to what needs it."
    keys = %w[a b c d z].to_h { [it.to_sym, format(message, it)] }
    expect_offense(<<~RUBY, **keys)
      class Slots
        def no_yield(value)
          was = Thread.current[:a]
                ^^^^^^^^^^^^^^^^^^ %{a}
          Thread.current[:a] = value
          ^^^^^^^^^^^^^^^^^^^^^^^^^^ %{a}
          work
        ensure
          Thread.current[:a] = was
          ^^^^^^^^^^^^^^^^^^^^^^^^ %{a}
        end

        def no_restore(value)
          was = Thread.current[:b]
                ^^^^^^^^^^^^^^^^^^ %{b}
          Thread.current[:b] = value
          ^^^^^^^^^^^^^^^^^^^^^^^^^^ %{b}
          yield
        ensure
          Thread.current[:b] = nil
          ^^^^^^^^^^^^^^^^^^^^^^^^ %{b}
          Thread.current[:z] = was
          ^^^^^^^^^^^^^^^^^^^^^^^^ %{z}
        end

        def no_set(value)
          was = Thread.current[:c]
                ^^^^^^^^^^^^^^^^^^ %{c}
          Thread.current[:z] = value
          ^^^^^^^^^^^^^^^^^^^^^^^^^^ %{z}
          yield
        ensure
          Thread.current[:c] = was
          ^^^^^^^^^^^^^^^^^^^^^^^^ %{c}
        end

        def no_body
        ensure
          Thread.current[:d] = nil
          ^^^^^^^^^^^^^^^^^^^^^^^^ %{d}
        end
      end
    RUBY
  end

  it "still flags a scope's slot read through another spelling or kept in the request store" do
    expect_offense(<<~RUBY)
      class Slots
        def held = Thread.current.fetch(:slot)
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^ `Thread.current.fetch` is global state keyed by the thread; pass the value to what needs it.

        def store = RequestStore.store[:slot]
                    ^^^^^^^^^^^^^^^^^^^^^^^^^ `RequestStore.store[:slot]` is global state keyed by the thread; pass the value to what needs it.

        def scoped(value)
          was = Thread.current[:slot]
          Thread.current[:slot] = value
          yield
        ensure
          Thread.current[:slot] = was
        end

        def requested(value)
          was = RequestStore.store[:slot]
                ^^^^^^^^^^^^^^^^^^^^^^^^^ `RequestStore.store[:slot]` is global state keyed by the thread; pass the value to what needs it.
          RequestStore.store[:slot] = value
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `RequestStore.store[:slot]` is global state keyed by the thread; pass the value to what needs it.
          yield
        ensure
          RequestStore.store[:slot] = was
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `RequestStore.store[:slot]` is global state keyed by the thread; pass the value to what needs it.
        end
      end
    RUBY
  end

  it "flags a class-level setting every caller shares, or every thread" do
    expect_offense(<<~RUBY)
      module Ahoy
        mattr_accessor :visit_duration
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `mattr_accessor :visit_duration` keeps one value on the class for every caller; pass it to the object that needs it.
        cattr_writer :quiet, :geocode
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `cattr_writer :quiet, …` keeps one value on the class for every caller; pass it to the object that needs it.
        thread_mattr_accessor :request_id
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `thread_mattr_accessor :request_id` is global state keyed by the thread; pass the value to what needs it.
      end
    RUBY
  end

  it "allows readers, a receiver's accessor, and a script's boot layer" do
    expect_no_offenses(<<~RUBY)
      mattr_accessor :boot

      module Ahoy
        mattr_reader :version, default: 1
        config.mattr_accessor(:visit)
      end
    RUBY
  end

  context "without CheckGlobals, as kata ships it" do
    let(:cop_config) { { "AllowedConstructors" => %w[Set Struct] } }

    it "reads the Singleton mixin and class-level instance caches only" do
      expect_offense(<<~RUBY)
        class Current < ActiveSupport::CurrentAttributes
          include Singleton
          ^^^^^^^^^^^^^^^^^ `include Singleton` makes one global instance; build the object where it is needed and pass it in.
          mattr_accessor :user
          def user = Thread.current[:user]
        end
      RUBY
    end
  end
end
