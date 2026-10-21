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
end
