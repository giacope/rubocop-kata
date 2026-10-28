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

  # mechanize's Page: eight `@x ||= ...` caches whose only plain assignment is `@x = nil` in `reset`.
  it "counts a memoized cache that a reset clears as a cache, not a field" do
    expect_no_offenses(<<~RUBY)
      class Page
        def initialize(body, encoding)
          @body = body
          @encoding = encoding
        end

        def links = @links ||= @body.scan(/href/)
        def forms = @forms ||= @body.scan(/form/)
        def title = @title ||= @body[/title/]

        def reencode(encoding)
          @encoding = encoding
          @links = nil
          @forms = nil
          @title = nil
        end
      end
    RUBY
  end

  it "still counts a cache a method also sets, and a field only ever cleared" do
    expect_offense(<<~RUBY)
      class Page
            ^^^^ `Page` encapsulates 5 fields (`@body`, `@encoding`, `@links`, `@forms` and `@title`); keep at most 4, and group the rest into an object of their own.
        def initialize(body, encoding)
          @body = body
          @encoding = encoding
        end

        def links = @links ||= @body.scan(/href/)
        def load = @links = @body.scan(/href/)
        def forms = @forms ||= @body.scan(/form/)

        def parse
          @forms, @body = @body.split
        end

        def reencode(encoding)
          @links = nil
          @forms = nil
          @title = nil
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
