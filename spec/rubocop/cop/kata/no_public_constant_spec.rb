# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::NoPublicConstant, :config) do
  let(:ruby_version) { 3.4 }
  let(:cop_config) { { "OwnedPaths" => [], "AllowedNames" => ["VERSION"] } }
  let(:advice) { "and make it private." }

  it "flags a value constant of another of the project's classes" do
    expect_offense(<<~RUBY)
      module Shop
        class Cart
          MAX_ITEMS = 50
        end

        module Settings
          TAX_RATE = 0.2
        end

        class Order
          def full? = @cart.size >= Cart::MAX_ITEMS
                                    ^^^^^^^^^^^^^^^ `Cart::MAX_ITEMS` is another object's public constant, shared state; ask `Cart` what it means, #{advice}
          def tax = @cents * ::Shop::Settings::TAX_RATE
                             ^^^^^^^^^^^^^^^^^^^^^^^^^^ `::Shop::Settings::TAX_RATE` is another object's public constant, shared state; ask `::Shop::Settings` what it means, #{advice}
        end
      end
    RUBY
  end

  it "allows a class's own constants, namespaces, classes, other libraries' constants and AllowedNames" do
    expect_no_offenses(<<~RUBY)
      module Shop
        module GDS
          class Campaign
          end
        end

        class Cart
          LIMIT = 50
          def full? = @lines.size >= Cart::LIMIT
          def big = Float::INFINITY
          def version = Shop::VERSION
          def campaign = Shop::GDS
          def kind = Shop::Cart
          def none = Missing::LIMIT
          def plain = LIMIT
          def single = Shop::X
        end
      end
    RUBY
  end
end
