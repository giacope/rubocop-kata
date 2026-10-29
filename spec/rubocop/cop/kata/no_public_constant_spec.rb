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
  # hashira's Coupling::Definition (fp/hashira-1): a `Data.define` block is the class body of the constant it is
  # assigned to, so `Definition#engine?` reads its own constant.
  it "allows a class built by Data.define, Struct.new or Class.new reading its own constant" do
    expect_no_offenses(<<~RUBY)
      module Demo
        Definition =
          Data.define(:superclass) do
            def engine? = Demo::Definition::ENGINES.include?(superclass)
          end

        Definition::ENGINES = %w[Rails::Engine].freeze

        Point = Struct.new(:x) do
          def origin? = x == Demo::Point::ORIGIN
        end

        Point::ORIGIN = 0

        Demo::Shape = Class.new do
          def sides = Demo::Shape::SIDES
        end

        Shape::SIDES = 4
      end
    RUBY
  end

  it "still flags another class's block, or a block that is not the constant's body, reading it" do
    expect_offense(<<~RUBY)
      module Demo
        Definition = Data.define(:superclass)
        Definition::ENGINES = %w[Rails::Engine].freeze

        Other =
          Data.define(:superclass) do
            def engine? = Demo::Definition::ENGINES.include?(superclass)
                          ^^^^^^^^^^^^^^^^^^^^^^^^^ `Demo::Definition::ENGINES` is another object's public constant, shared state; ask `Demo::Definition` what it means, and make it private.
          end

        Definition.tap do
          def engines = Demo::Definition::ENGINES
                        ^^^^^^^^^^^^^^^^^^^^^^^^^ `Demo::Definition::ENGINES` is another object's public constant, shared state; ask `Demo::Definition` what it means, and make it private.
        end

        Kinds = [Data.define(:kind) { def engines = Demo::Definition::ENGINES }].freeze
                                                    ^^^^^^^^^^^^^^^^^^^^^^^^^ `Demo::Definition::ENGINES` is another object's public constant, shared state; ask `Demo::Definition` what it means, and make it private.
      end

      def engines = Demo::Definition::ENGINES
                    ^^^^^^^^^^^^^^^^^^^^^^^^^ `Demo::Definition::ENGINES` is another object's public constant, shared state; ask `Demo::Definition` what it means, and make it private.
    RUBY
  end

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

  # mechanize: `Net::NTLM::Message` names rubyntlm's module through a `Net` the project reopens.
  it "allows an acronym constant that is the namespace of another constant" do
    expect_no_offenses(<<~RUBY)
      module Net
      end

      class Net::HTTP
        def start = true
      end

      class Agent
        def negotiate = Net::NTLM::Message::Type1.new.encode64
        def decode(text) = Net::NTLM::Message.decode64(text)
      end
    RUBY
  end

  it "still flags the acronym constant read as a value, or sent a message" do
    expect_offense(<<~RUBY)
      module Net
      end

      class Net::HTTP
        def start = true
      end

      class Agent
        def mode = Net::NTLM
                   ^^^^^^^^^ `Net::NTLM` is another object's public constant, shared state; ask `Net` what it means, #{advice}
        def size = Net::NTLM.size
                   ^^^^^^^^^ `Net::NTLM` is another object's public constant, shared state; ask `Net` what it means, #{advice}
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
