# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::PublicSurface, :config) do
  let(:ruby_version) { 3.4 }
  let(:cop_config) { { "Max" => 4, "Protocols" => %w[to_s ==], "AllowedPatterns" => ["\\Aon_"] } }

  it "flags a class exposing more public methods than the limit" do
    expect_offense(<<~RUBY)
      class Customer
            ^^^^^^^^ `Customer` exposes 5 public methods (`greeting`, `signature`, `memo`, `email` and `email=`); keep at most 4, and move the rest to an object of their own.
        attr_accessor :email

        def greeting = 1
        def signature = 2
        memoize def memo = 3
      end
    RUBY
  end

  it "does not count hidden methods, class methods, protocols or callbacks" do
    expect_no_offenses(<<~RUBY)
      class Customer
        attr_reader :name
        private attr_reader :token
        def greeting = 1
        def signature = 2
        def to_s = "x"
        def ==(other) = true
        def on_send(node) = node
        def self.build = new
        def initials = 3
        private def secret = 4
        def hidden = 5
        private :hidden

        class << self
          def other = 6
        end

        protected

        def rank = 7

        private

        def helper = 8
        attr_writer :code
      end
    RUBY
  end

  it "allows an empty class" do
    expect_no_offenses(<<~RUBY)
      class Customer; end
    RUBY
  end
end
