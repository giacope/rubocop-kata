# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::NoSingleton, :config) do
  let(:ruby_version) { 3.4 }

  let(:cop_config) { { "AllowedConstructors" => %w[Set Struct] } }

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

  # beis's `@all ||= Codelist.new(…).map { … }`, npq's `YAML.load(ERB.new(…).result)`: the cache holds the result.
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

  # The V1 conformance case P17: `Current.account` read from a model, through CurrentAttributes.
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

  # searchkick, timecop, counter_culture, bullet keep their switches in the thread.
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
          ^^^^^^^^^^^^^^^^^ `Fiber[:state]` is global state keyed by the thread; pass the value to what needs it.
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

  # ahoy, mailboxer, delayed_job: settings kept in class variables behind accessors.
  it "flags a class-level setting every caller shares" do
    expect_offense(<<~RUBY)
      module Ahoy
        mattr_accessor :visit_duration
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `mattr_accessor :visit_duration` keeps one value on the class for every caller; pass it to the object that needs it.
        cattr_writer :quiet, :geocode
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `cattr_writer :quiet, …` keeps one value on the class for every caller; pass it to the object that needs it.
        thread_mattr_accessor :request_id
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `thread_mattr_accessor :request_id` keeps one value on the class for every caller; pass it to the object that needs it.
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
end
