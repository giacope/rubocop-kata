# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::NoNilArgument, :config) do
  let(:ruby_version) { 3.4 }
  let(:cop_config) { { "AllowedMethods" => ["as_json"] } }
  let(:message) { "defaults to nil, then is asked if it came: two methods in one. #{advice}" }
  let(:advice) { "Split them, or default to a null object." }

  it "flags a nil default the method tests with nil?" do
    expect_offense(<<~RUBY)
      def discounted(coupon = nil)
                     ^^^^^^^^^^^^ `coupon` #{message}
        return @cents if coupon.nil?
        @cents - coupon.cents
      end
    RUBY
  end

  it "flags every way of asking whether the argument came" do
    expect_offense(<<~RUBY)
      def a(x = nil) = x&.name
            ^^^^^^^ `x` #{message}
      def b(x: nil) = x || 0
            ^^^^^^ `x` #{message}
      def c(x = nil) = x ? 1 : 0
            ^^^^^^^ `x` #{message}
      def d(x = nil) = (1 unless x)
            ^^^^^^^ `x` #{message}
      def e(x = nil) = x.present?
            ^^^^^^^ `x` #{message}
      def f(x = nil) = !x
            ^^^^^^^ `x` #{message}
      def g(x = nil) = x == nil
            ^^^^^^^ `x` #{message}
      def h(x = nil) = nil != x
            ^^^^^^^ `x` #{message}
      def i(x = nil) = (1 if ready && x)
            ^^^^^^^ `x` #{message}
      def j(x = nil) = x.try(:name)
            ^^^^^^^ `x` #{message}
      def k(x = nil)
            ^^^^^^^ `x` #{message}
        x ||= 0
        x + 1
      end
      def l(x = nil)
            ^^^^^^^ `x` #{message}
        case x
        when nil then 0
        else x
        end
      end
      def m(x = nil)
            ^^^^^^^ `x` #{message}
        tick while x
      end
      def self.n(x = nil) = x.blank?
                 ^^^^^^^ `x` #{message}
    RUBY
  end

  it "flags a constructor's nil default kept in a field the class asks about" do
    expect_offense(<<~RUBY)
      class Signup
        def initialize(email, referrer: nil)
                              ^^^^^^^^^^^^^ `referrer` defaults to nil, and `@referrer` is asked if it came: two objects in one. Default to a null object.
          @email = email
          @referrer = referrer
        end

        def bonus = @referrer&.credit || 0
      end
    RUBY
  end

  it "allows a nil default the method only passes on" do
    expect_no_offenses(<<~RUBY)
      def fetch(key, default = nil) = @rows.fetch(key, default)
      def read(timeout: nil) = @socket.read(timeout: timeout)
      def wrap(x = nil) = [ready || x, ready && x]
      def same(x = nil) = x == other
    RUBY
  end

  it "allows a field the class never asks about, and a field copied from elsewhere" do
    expect_no_offenses(<<~RUBY)
      class Signup
        def initialize(email, referrer: nil, origin: 1)
          @email = email
          @referrer = referrer
          @origin = origin || referrer
        end

        def bonus = @referrer.credit
        def first = @email.nil?
      end
    RUBY
  end

  it "reads a field outside the class's instance methods as another object's" do
    expect_no_offenses(<<~RUBY)
      class Signup
        def initialize(referrer = nil)
          @referrer = referrer
        end

        def self.blank = @referrer.nil?

        class Inner
          def empty? = @referrer.nil?
        end
      end
    RUBY
  end

  it "keeps a nested scope's own variable apart" do
    expect_no_offenses(<<~RUBY)
      def outer(x = nil)
        define_method(:y) { 1 }
        def inner(x) = x.nil?
        x
      end
      module Holder
        def initialize(x = nil)
          @x = x
        end

        def gone? = @x.nil?
      end
    RUBY
  end

  it "allows the protocols in AllowedMethods" do
    expect_no_offenses(<<~RUBY)
      def as_json(options = nil) = super(options || {})
    RUBY
  end

  it "allows a nil default with no body" do
    expect_no_offenses(<<~RUBY)
      def ping(x = nil); end
      def initialize(x = nil); end
    RUBY
  end
end
