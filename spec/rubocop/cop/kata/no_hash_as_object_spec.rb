# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::NoHashAsObject, :config) do
  let(:ruby_version) { 3.4 }

  let(:cop_config) { { "MaxKeys" => 4 } }

  it "flags hashes with enough keys to be an object" do
    expect_offense(<<~RUBY)
      user = { name: "a", email: "b", age: 1, role: :admin }
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 4 keys travelling together are an object without a name.
    RUBY
  end

  it "allows keyword arguments to any call, even beside a block argument" do
    expect_no_offenses(<<~RUBY)
      form_with model: user, url: path, id: "composer", data: options, &block
      foo&.create(name: "a", email: "b", age: 1, role: :admin)
      super(name: "a", email: "b", age: 1, role: :admin)
      yield(name: "a", email: "b", age: 1, role: :admin)
    RUBY
  end

  it "flags a braced hash that is not the last argument" do
    expect_offense(<<~RUBY)
      enum :status, { draft: 0, sent: 1, paid: 2, void: 3 }, prefix: true
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 4 keys travelling together are an object without a name.
      build({ name: "a", email: "b", age: 1, role: :admin }, &block)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 4 keys travelling together are an object without a name.
    RUBY
  end

  it "flags a hash handed to something that is not a call" do
    expect_offense(<<~RUBY)
      [name: "a", email: "b", age: 1, role: :admin]
       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 4 keys travelling together are an object without a name.
    RUBY
  end

  it "allows a table a constant names, frozen or not" do
    expect_no_offenses(<<~RUBY)
      STATUS_ICONS = { queued: "clock", running: "play", finished: "check", failed: "x" }
      STATUS_COLORS = { queued: "grey", running: "blue", finished: "green", failed: "red" }.freeze
      Billing::RATES = { gold: 1, silver: 2, bronze: 3, basic: 4 }
    RUBY
  end

  it "allows the rows of an array table a constant names, frozen or not" do
    expect_no_offenses(<<~RUBY)
      FLAVORS = [
        { id: "t1.micro", name: "Micro", cores: 1, ram: 613 },
        { id: "m1.small", name: "Small", cores: 1, ram: 1740 }
      ].freeze
      Sizes::ROWS = [[{ id: 1, name: "a", cores: 1, ram: 2 }]]
    RUBY
  end

  context "with TableMethods" do
    let(:cop_config) { { "MaxKeys" => 4, "TableMethods" => ["enum"] } }

    it "allows the value table such a call takes, and nothing else" do
      expect_offense(<<~RUBY)
        enum :status, { draft: 0, sent: 1, paid: 2, void: 3 }, prefix: true
        build({ name: "a", email: "b", age: 1, role: :admin }, &block)
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 4 keys travelling together are an object without a name.
      RUBY
    end
  end

  it "allows the rows of a table a constant names, frozen or not" do
    expect_no_offenses(<<~RUBY)
      LABELS = {
        email: { en: "Email", es: "Correo", fr: "Courriel", de: "E-Mail" },
        name: { en: "Name", es: "Nombre", fr: "Nom", de: "Name" }.freeze,
        nested: { deep: { en: "a", es: "b", fr: "c", de: "d" } }
      }.freeze
    RUBY
  end

  it "still flags a hash a table row only builds on" do
    expect_offense(<<~RUBY)
      LABELS = { email: { en: "Email", es: "Correo", fr: "Courriel", de: "E-Mail" }.merge(extra) }
                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 4 keys travelling together are an object without a name.
    RUBY
  end

  it "still flags a hash a constant only builds on, or a local holds frozen" do
    expect_offense(<<~RUBY)
      DEFAULT = { name: "a", email: "b", age: 1, role: :admin }.merge(extra)
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 4 keys travelling together are an object without a name.
      user = { name: "a", email: "b", age: 1, role: :admin }.freeze
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 4 keys travelling together are an object without a name.
    RUBY
  end

  it "allows small hashes and keyword arguments" do
    expect_no_offenses(<<~RUBY)
      user = { name: "a", email: "b" }
      create(name: "a", email: "b", age: 1, role: :admin)
    RUBY
  end

  context "with the shipped defaults" do
    let(:cop_config) { RuboCop::ConfigLoader.default_configuration.for_cop("Kata/NoHashAsObject") }

    it "allows the hash a serialization method returns" do
      expect_no_offenses(<<~RUBY)
        def to_h = { cents: 1, currency: "EUR", scale: 2, rounding: :up }
        def as_json(*) = { cents: 1, currency: "EUR", scale: 2, rounding: :up }
        def self.to_h = { cents: 1, currency: "EUR", scale: 2, rounding: :up }
      RUBY
    end

    it "still flags the same hash anywhere else" do
      expect_offense(<<~RUBY)
        def payload = { cents: 1, currency: "EUR", scale: 2, rounding: :up }
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 4 keys travelling together are an object without a name.
      RUBY
    end
  end

  context "with Sorbet" do
    let(:cop_config) { { "MaxKeys" => 4, "Sorbet" => true } }

    it "reads a table a constant names through T.let" do
      expect_no_offenses(<<~RUBY)
        TYPED = T.let([{ name: "a", email: "b", age: 1, role: :admin }].freeze, T::Array[T::Hash[Symbol, T.untyped]])
        CODES = T.let({ find: /a/, link: /b/, copy: /c/, lock: /d/ }.freeze, T::Hash[Symbol, Regexp])
      RUBY
    end
  end

  it "reads a braced hash passed last as a hash, and only bare keywords as call syntax" do
    expect_offense(<<~RUBY)
      jobs.push({ id: 1, name: "a", cores: 2, ram: 4 })
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 4 keys travelling together are an object without a name.
      jobs.push(id: 1, name: "a", cores: 2, ram: 4)
    RUBY
  end

  it "reads T.let as a call where the project does not use Sorbet" do
    expect_offense(<<~RUBY)
      CODES = T.let({ find: /a/, link: /b/, copy: /c/, lock: /d/ }, T::Hash[Symbol, Regexp])
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 4 keys travelling together are an object without a name.
    RUBY
  end

  context "with CheckTravel, the strict profile's reading of the keys a method hands on" do
    let(:cop_config) do
      RuboCop::ConfigLoader.default_configuration.for_cop("Kata/NoHashAsObject").merge("CheckTravel" => true)
    end
    let(:answered) { "keys a method answers together are an object without a name; answer an object that knows them." }
    let(:read) { "a hash used as an object without a name; take an object that answers them." }

    # V1 P37: a 3-key payment built in one class and read by key in another passed (MaxKeys 4, reads not followed).
    it "follows a hash a method answers, and the parameter that reads it by key" do
      expect_offense(<<~RUBY)
        class Checkout
          def payment
            { amount: @cart.total, currency: "usd", source: @card.token }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 3 #{answered}
          end
        end
        class Gateway
          def charge(payment)
                     ^^^^^^^ `payment` is read by its keys (`amount`, `currency`, `source`): #{read}
            "\#{payment[:amount]} \#{payment.fetch(:currency)} via \#{payment.dig(:source)}"
          end
        end
      RUBY
    end

    it "follows the keys through a return, a branch, a local, a map and the rows of an answered array" do
      expect_offense(<<~RUBY)
        class Report
          def rows = @lines.map { { sku: it.sku, total: it.total } }
                                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 2 #{answered}
          def line(found)
            return { sku: nil, total: z } unless found
                   ^^^^^^^^^^^^^^^^^^^^^^ 2 #{answered}
            summary = { sku: found.sku, total: found.total }
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 2 #{answered}
            summary
          end
          def pair = [{ id: x, name: "a" }]
                      ^^^^^^^^^^^^^^^^^^^^ 2 #{answered}
        end
      RUBY
    end

    it "follows a hash handed to the project's own code, and leaves one handed to a library" do
      expect_offense(<<~RUBY)
        class Checkout
          def pay(total)
            charge(Payment.new({ amount: total, currency: "usd" }))
                               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 2 keys handed together to `new` are an object without a name; pass an object that knows them.
            payment = { amount: total, currency: "usd" }
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 2 keys handed together to `charge` are an object without a name; pass an object that knows them.
            self.charge(payment)
            render json: { amount: total, currency: "usd" }
            Faraday.post("/pay", { amount: total, currency: "usd" })
            Order.create({ amount: total, currency: "usd" })
            Order.new({ amount: total, currency: "usd" })
            @gateway.charge({ amount: total, currency: "usd" })
          end

          def charge(payment) = payment
        end
        class Order < ApplicationRecord
          def total = 1
        end
        class Payment
          def initialize(fields)
            @fields = fields
          end
        end
      RUBY
    end

    it "leaves keyword arguments, tables, string keys, a single key and the serialization protocol" do
      expect_no_offenses(<<~RUBY)
        class Shop
          LABELS = { draft: "Draft", sent: "Sent" }.freeze
          def label = LABELS
          def notify(mailer) = mailer.deliver(subject: "Hi", body: "There")
          def headers = { "Content-Type" => "text/plain", "Accept" => "*/*" }
          def wrapped = { data: @items }
          def sources = { collection: "documents", browse: "children", taxon: ["taxon", 1, nil] }
          def to_h = { name: @name, email: @email }
          def to_payload = { name: @name, email: @email }
          def present = { name: @name, email: @email }
        end
        module FormHelper
          def error_link(error) = { text: error.message, href: error.anchor }
        end
        class SummaryPresenter
          def row(item) = { key: item.name, value: item.total }
          def as_json(options) = { name: options[:only], email: options[:except] }
          def call(env) = [env["PATH_INFO"], env["REQUEST_METHOD"]]
          def size(options) = options[:size]
          def merged(options) = options.merge(size: 1)[:size]
          def kept
            @options = { size: 1, color: :red }
          end
        end
      RUBY
    end

    it "follows the keys nested in an answered hash, a class method, the tail of a body and both branches" do
      expect_offense(<<~RUBY)
        class Feed
          def envelope = { data: { id: x, name: "a" } }
                                 ^^^^^^^^^^^^^^^^^^^^ 2 #{answered}
          def self.empty = { id: z, name: "" }
                           ^^^^^^^^^^^^^^^^^^^ 2 #{answered}
          def entry
            log
            { id: x, name: "a" }
            ^^^^^^^^^^^^^^^^^^^^ 2 #{answered}
          end
          def pick(flag) = flag ? { id: x, name: "a" } : { id: y, name: "b" }
                                  ^^^^^^^^^^^^^^^^^^^^ 2 #{answered}
                                                         ^^^^^^^^^^^^^^^^^^^^ 2 #{answered}
          def post = notify({ id: x, name: "a" })
                            ^^^^^^^^^^^^^^^^^^^^ 2 keys handed together to `notify` are an object without a name; pass an object that knows them.
          def made = Entry.build({ id: x, name: "a" })
                                 ^^^^^^^^^^^^^^^^^^^^ 2 keys handed together to `build` are an object without a name; pass an object that knows them.
          def notify(entry) = entry
        end
        class Entry
          def self.build(fields) = fields
        end
      RUBY
    end

    it "leaves keys that do not leave the method, a double splat, and keyword splats read by key" do
      expect_no_offenses(<<~RUBY)
        { id: x, name: "a" }
        entry = { id: x, name: "a" }
        broadcast_feed(entry)
        class Feed
          def discarded
            { id: x, name: "a" }
            nil
          end
          def each_entry = @rows.each { { id: it.id, name: it.name } }
          def tested = ({ id: x, name: "a" } ? 1 : 2)
          def merged(rest) = { id: x, **rest }
          def options(**opts) = [opts[:id], opts[:name]]
          def empty(payment)
          end
        end
      RUBY
    end

    # searchkick's Faraday middleware reads `env[:url]` and `env[:request]`; its models answer `search_data`.
    it "leaves a public method a library's superclass calls, but not one the project's own ancestor defines" do
      expect_offense(<<~RUBY)
        class Middleware < Faraday::Middleware
          def call(env) = [env[:url], env[:request]]
          def search_data = { name: @name, color: @color }

          private

          def helper(env) = [env[:url], env[:request]]
                     ^^^ `env` is read by its keys (`url`, `request`): #{read}
        end
        class Base
          def call(env) = env
        end
        class Plain < Base
          def call(env) = [env[:url], env[:request]]
                   ^^^ `env` is read by its keys (`url`, `request`): #{read}
          def self.load(env) = [env[:url], env[:request]]
                        ^^^ `env` is read by its keys (`url`, `request`): #{read}
        end
      RUBY
    end

    it "follows the keys through every local they are copied into" do
      expect_offense(<<~RUBY)
        class Ledger
          def summary
            built = { id: x, name: y }
                    ^^^^^^^^^^^^^^^^^^ 2 #{answered}
            copy = built
            copy
          end
          def post
            payment = { id: x, name: y }
                      ^^^^^^^^^^^^^^^^^^ 2 keys handed together to `charge` are an object without a name; pass an object that knows them.
            sent = payment
            charge(sent)
          end
          def charge(payment) = payment
        end
      RUBY
    end

    it "leaves keys a script discards, a local copied in a circle, a double splat and string keys" do
      expect_no_offenses(<<~RUBY)
        return { id: x, name: y } if ready
        class Ledger
          def circle
            first = { id: x, name: y }
            second = first
            first = second
            nil
          end
          def merged(rest) = { id: x, name: y, **rest }
          def fields = { "id" => x, "name" => y }
        end
      RUBY
    end

    it "leaves a file that is a hash and nothing else" do
      expect_no_offenses("{ id: x, name: y }\n")
    end

    it "leaves a parameter whose name a block or a reassignment shadows" do
      expect_no_offenses(<<~RUBY)
        class Shop
          def totals(row, rows) = rows.map { |row| row[:total] + row[:tax] } + [row[:total]]
          def fresh(payment)
            payment = Payment.new(payment)
            [payment[:amount], payment[:currency]]
          end
        end
      RUBY
    end
  end
end
