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

  it "allows small hashes and keyword arguments" do
    expect_no_offenses(<<~RUBY)
      user = { name: "a", email: "b" }
      create(name: "a", email: "b", age: 1, role: :admin)
    RUBY
  end
end
