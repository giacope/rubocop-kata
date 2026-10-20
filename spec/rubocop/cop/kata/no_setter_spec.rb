# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::NoSetter, :config) do
  let(:ruby_version) { 3.4 }

  it "flags the macros that mint a setter" do
    expect_offense(<<~RUBY)
      class Account
        attr_writer :balance
        ^^^^^^^^^^^ `attr_writer` mints a setter; take the value in the constructor and return a new object to change it.
        attr_accessor :owner, :limit
        ^^^^^^^^^^^^^ `attr_accessor` mints a setter; take the value in the constructor and return a new object to change it.
      end
    RUBY
  end

  it "flags a setter method, on an instance or on the class" do
    expect_offense(<<~RUBY)
      class Account
        def balance=(value)
            ^^^^^^^^ `balance=` is a setter; take the value in the constructor and return a new object to change it.
          @balance = value
        end

        def self.default=(account)
                 ^^^^^^^^ `default=` is a setter; take the value in the constructor and return a new object to change it.
          @default = account
        end
      end
    RUBY
  end

  it "allows readers, comparisons, and a collection's element writer" do
    expect_no_offenses(<<~RUBY)
      class Account
        attr_reader :balance

        def ==(other) = balance == other.balance
        def <=(other) = balance <= other.balance
        def !=(other) = !(self == other)

        def []=(key, value)
          @entries.store(key, value)
        end
      end
    RUBY
  end

  it "leaves a macro called on another object alone" do
    expect_no_offenses(<<~RUBY)
      Account.attr_accessor(:owner)
      klass.attr_writer :balance
    RUBY
  end

  it "flags a setter minted by define_method, with a literal or an interpolated name" do
    expect_offense(<<~'RUBY')
      class Box
        %i[width height].each do |side|
          define_method(:"#{side}=") { |value| instance_variable_set(:"@#{side}", value) }
                        ^^^^^^^^^^^ `:"#{side}="` is a setter; take the value in the constructor and return a new object to change it.
        end
        define_method(:depth=) { |value| @depth = value }
                      ^^^^^^^ `:depth=` is a setter; take the value in the constructor and return a new object to change it.
        define_method("label=") { |value| @label = value }
                      ^^^^^^^^ `"label="` is a setter; take the value in the constructor and return a new object to change it.
      end
    RUBY
  end

  it "leaves define_method minting a reader, an element writer, or another object's method" do
    expect_no_offenses(<<~'RUBY')
      class Box
        define_method(:depth) { @depth }
        define_method(:"#{name}_count") { 0 }
        define_method(:[]=) { |key, value| @entries.store(key, value) }
        other.define_method(:depth=) { |value| value }
      end
    RUBY
  end
end
