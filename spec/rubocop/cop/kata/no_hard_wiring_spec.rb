# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::NoHardWiring, :config) do
  let(:ruby_version) { 3.4 }
  let(:cop_config) { { "OwnedPaths" => [], "RootSuperclasses" => ["RuboCop::Cop::Base"] } }

  it "flags an instance method that builds a collaborator of the project's and talks to it" do
    expect_offense(<<~RUBY)
      module Shop
        class Gateway
        end

        class Mailbox
        end

        class Checkout
          def receipt
            Gateway.new("live").charge(@cents)
            ^^^^^^^^^^^^^^^^^^^ `receipt` builds the `Gateway` it talks to; take one in the constructor, with this `new` as the parameter's default.
          end

          def complete
            box = Shop::Mailbox.new(host) { |config| config.tls }
                  ^^^^^^^^^^^^^^^^^^^^^^^ `complete` builds the `Shop::Mailbox` it talks to; take one in the constructor, with this `new` as the parameter's default.
            box&.deliver(receipt)
          end
        end
      end
    RUBY
  end

  it "allows an object built to be returned, passed on or kept" do
    expect_no_offenses(<<~RUBY)
      module Shop
        class Gateway
        end

        class Cart
          def with(item) = Cart.new(@items + [item])
          def wrapped = Gateway.new(Gateway.new("live"))
          def handed = @log.push(Gateway.new("live"))
          def named
            gateway = Gateway.new("live")
            gateway
          end
          def other
            gateway = Gateway.new("live")
            @log.write(gateway)
            ready.go
          end
          def again = self.class.new(@items).size
          def plain = new.size
        end
      end
    RUBY
  end

  it "allows the seams: constructors, parameter defaults and class methods" do
    expect_no_offenses(<<~RUBY)
      module Shop
        class Gateway
        end

        class Checkout
          def initialize(cents, gateway = Gateway.new("live"))
            @rate = Gateway.new("test").rate
          end

          def receipt(gateway: Gateway.new("live")) = gateway.charge(@cents)

          def self.build = Gateway.new("live").checkout

          class << self
            def other = Gateway.new("live").checkout
          end
        end
      end
    RUBY
  end

  it "allows the classes of Ruby and of other libraries" do
    expect_no_offenses(<<~RUBY)
      module Shop
        class Checkout
          def receipt = Set.new(@items).size
          def remote = Net::HTTP.new(@host).start
          def stamp = Shop::Missing.new.call
        end
      end
    RUBY
  end

  it "reads a class building itself through its namespace as the class itself" do
    expect_no_offenses(<<~RUBY)
      module Shop
        class Cart
          def with(item) = Shop::Cart.new(@items + [item]).compact
        end
      end
    RUBY
  end

  it "judges a module's instance methods too" do
    expect_offense(<<~RUBY)
      class Gateway
      end

      module Billing
        def charge = Gateway.new.charge
                     ^^^^^^^^^^^ `charge` builds the `Gateway` it talks to; take one in the constructor, with this `new` as the parameter's default.
      end
    RUBY
  end

  it "allows a class the framework builds, which cannot be handed a collaborator" do
    expect_no_offenses(<<~RUBY)
      class Gateway
      end

      class Check < RuboCop::Cop::Base
        def on_send(node) = Gateway.new.charge(node)
      end
    RUBY
  end

  it "ignores a new outside any method" do
    expect_no_offenses(<<~RUBY)
      class Gateway
      end

      Gateway.new.charge
    RUBY
  end
end
