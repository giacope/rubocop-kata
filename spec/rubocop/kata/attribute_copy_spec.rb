# frozen_string_literal: true

RSpec.describe(RuboCop::Kata::AttributeCopy) do
  include TabledCop

  let(:cop) { RuboCop::Cop::Lint::SelfAssignment.new(RuboCop::Config.new) }

  # mechanize's `cookie.expires = cookie.expires`: http-cookie's reader computes the expiry, its writer pins it.
  it "leaves an attribute copied through a writer it cannot see, or one the class defines" do
    source = <<~RUBY
      def freeze_expiry(cookie)
        cookie.expires = cookie.expires
        cookie&.expires = cookie.expires
        @cookie.name = @cookie.name
      end

      class Cookie
        def expires = @expires || @created_at + @max_age
        def label=(text)
          @label = text.strip
        end

        def pin = self.expires = self.expires
        def tidy = self.label = self.label
      end
    RUBY
    expect([processed(source).valid_syntax?, offenses(source)]).to(eq([true, []]))
  end

  it "still reports a plain attribute copied onto itself, and the other self-assignments" do
    source = <<~RUBY
      class Cookie
        attr_accessor :expires

        def pin = self.expires = self.expires
        def safe = self&.expires = self.expires
        def key = @jar[:a] = @jar[:a]
        def own = @x = @x
      end
    RUBY
    expect(offenses(source).map(&:line)).to(eq([4, 5, 6, 7]))
  end
end
