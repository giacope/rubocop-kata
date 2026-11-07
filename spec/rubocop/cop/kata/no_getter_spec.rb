# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::NoGetter, :config) do
  let(:ruby_version) { 3.4 }
  let(:advice) { "tell the object what to do with its fields, or have it print itself." }

  it "flags a public attr_reader, naming its fields" do
    expect_offense(<<~RUBY)
      class Customer
        attr_reader :first_name, :last_name
        ^^^^^^^^^^^ `attr_reader` exposes `first_name`, `last_name` as a getter; #{advice}
        attr :email
        ^^^^ `attr_reader` exposes `email` as a getter; #{advice}
      end
    RUBY
  end

  it "flags a method that only returns the field of its name" do
    expect_offense(<<~RUBY)
      class Account
        def balance = @balance
            ^^^^^^^ `balance` is a getter; tell the object what to do with `@balance`, or have it print itself.

        def total
            ^^^^^ `total` is a getter; tell the object what to do with `@total`, or have it print itself.
          @total
        end
      end
    RUBY
  end

  it "flags a Struct or Data, a getter for every field" do
    expect_offense(<<~RUBY)
      module Shop
        Address = Struct.new(:street, :city)
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^ `Struct.new` mints a getter for every field, a data bag; write a class whose methods do the work with its fields.
        Point = ::Data.define(:left, :top) do
                ^^^^^^^^^^^^^^^^^^^^^^^^^^ `Data.define` mints a getter for every field, a data bag; write a class whose methods do the work with its fields.
          def norm = left + top
        end
      end
    RUBY
  end

  it "allows a Struct or Data whose block makes every member's reader private or protected" do
    expect_no_offenses(<<~RUBY)
      module Shop
        Cursor =
          Data.define(:position, :inside_def) do
            private(*members)

            def enter(node) = with(position: position + 1)
          end
        Pair = Struct.new(:left, "right", keyword_init: true) do
          protected :left
          private :right
        end
        Span = Struct.new(:from, :to) { private :from, :to }
      end
    RUBY
  end

  it "names the members a bag's block leaves public, and reads only its bare hiding calls" do
    bag = "a data bag; write a class whose methods do the work with its fields."
    expect_offense(<<~RUBY)
      module Shop
        Cursor = Data.define(:position, :inside_def, :depth) do
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `Data.define` mints a getter for `inside_def`, `depth`, #{bag}
          private :position
          private
          def helper = 1
        end
        Pair = Struct.new(:left, :right, keyword_init: true) do
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `Struct.new` mints a getter for every field, #{bag}
          self.private(*members)
          public(*members)
          private(*fields)
          private(*self.members)
          private def other = 1
          attr_writer :other
        end
        Span = Struct.new(:from, :to) { protected(:from) }
               ^^^^^^^^^^^^^^^^^^^^^^ `Struct.new` mints a getter for `to`, #{bag}
      end
    RUBY
  end

  it "allows private and protected readers, in every spelling" do
    expect_no_offenses(<<~RUBY)
      class Account
        private attr_reader :balance
        protected attr_reader :id
        attr_reader :owner
        private :owner
        def name = @name
        private :name

        protected

        attr_reader :rate

        private

        attr_reader :cents
        def total = @total
      end
    RUBY
  end

  it "allows a method doing more than returning its field, and the other readers" do
    expect_no_offenses(<<~RUBY)
      class Account
        def balance = @balance + @pending
        def total = @sum
        def self.instance = @instance
        def empty; end
        record.attr_reader(:x)
        attr_reader
        Struct.new
        Data.define
        Struct.new(*FIELDS)
        Other.new(:a)
      end
    RUBY
  end
end
