# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::FieldCount, :config) do
  let(:ruby_version) { 3.4 }
  let(:cop_config) { { "Max" => 4 } }

  it "flags a class assigning more fields than the limit" do
    expect_offense(<<~RUBY)
      class Address
            ^^^^^^^ `Address` encapsulates 5 fields (`@street`, `@city`, `@zip`, `@country` and `@phone`); keep at most 4, and group the rest into an object of their own.
        def initialize(street, city, zip, country)
          @street = street
          @city = city
          @zip = zip
          @country = country
        end

        def call(phone)
          @phone = phone
          @street = nil
        end
      end
    RUBY
  end

  it "counts the fields attr macros name" do
    expect_offense(<<~RUBY)
      module Shop
        class Signup
              ^^^^^^ `Signup` encapsulates 6 fields (`@plan`, `@email`, `@password`, `@name`, `@company` and `@phone`); keep at most 4, and group the rest into an object of their own.
          attr_accessor :email, :password, :name
          attr_reader :company
          attr :phone

          def initialize(plan)
            @plan = plan
          end
        end
      end
    RUBY
  end

  it "allows a class at the limit, memoized answers, and other objects' fields" do
    expect_no_offenses(<<~RUBY)
      class Place
        attr_reader :zip
        record.attr_reader(:a, :b, :c, :d)

        def initialize(zip, city, country)
          @zip = zip
          @city = city
          @country = country
        end

        def label = @label ||= "\#{@zip} \#{@city}"
        def total = @_total ||= 1

        def self.build = @cache = 1

        class << self
          def cache = @store = 1
        end

        class Inner
          def initialize = @x = @y = @z = 1
        end
      end
    RUBY
  end

  it "allows an empty class" do
    expect_no_offenses(<<~RUBY)
      class Place; end
    RUBY
  end
end
