# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::NoHashAsObject, :config) do
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
end
