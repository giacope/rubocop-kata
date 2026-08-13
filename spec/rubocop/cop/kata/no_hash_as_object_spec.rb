# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::NoHashAsObject, :config) do
  let(:cop_config) { { "MaxKeys" => 4 } }

  it "flags hashes with enough keys to be an object" do
    expect_offense(<<~RUBY)
      user = { name: "a", email: "b", age: 1, role: :admin }
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
