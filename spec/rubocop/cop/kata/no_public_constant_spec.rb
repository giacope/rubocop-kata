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
          def single = Gift::X
        end

        class Gift
          X = 1
        end
      end
    RUBY
  end

  # support's Support::GDS: a module that only namespaces classes is not a value.
  it "allows a namespace under another class, whose classes the file or the project defines" do
    expect_no_offenses(<<~RUBY)
      module Shop
        class Cart
          def size = 1

          module GDS
            class Campaign
            end
          end
        end

        class Order
          def campaign = Cart::GDS
        end
      end
    RUBY
  end

  context "with the project's files" do
    include ProjectFiles

    let(:setting) { { "Kata/NoPublicConstant" => cop_config.merge("OwnedPaths" => ["lib/**/*.rb"]) } }

    it "allows a namespace whose classes another file defines" do
      files = {
        "lib/shop/cart/gds/campaign.rb" => "class Shop::Cart\n  module GDS\n    class Campaign\n    end\n  end\nend\n",
        "lib/shop/order.rb" => "module Shop\n  class Cart\n  end\n\n  class Order\n    def a = Cart::GDS\n  end\nend\n"
      }
      expect(project_offenses(files, "lib/shop/order.rb")).to(be_empty)
    end
  end
end
