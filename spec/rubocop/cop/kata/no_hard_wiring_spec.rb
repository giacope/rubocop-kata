# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::NoHardWiring, :config) do
  let(:ruby_version) { 3.4 }
  let(:cop_config) { { "OwnedPaths" => [], "RootSuperclasses" => ["RuboCop::Cop::Base"] } }

  def seam = "take one in the constructor, with this `new` as the parameter's default."

  it "flags a collaborator built to be talked to for its effects" do
    expect_offense(<<~RUBY, seam: seam)
      module Shop
        class Gateway
        end

        class Mailbox
        end

        class Checkout
          def receipt
            Gateway.new("live").charge(@cents)
            ^^^^^^^^^^^^^^^^^^^ `receipt` builds the `Gateway` it talks to; %{seam}
            rate = 1
            Mailbox.new(rate)
          end

          def check(taxon)
            taxon = Gateway.new(taxon, prefix: PREFIX)
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `check` builds the `Gateway` it talks to; %{seam}
            taxon.valid?
          end

          def complete
            box = Shop::Mailbox.new(host) { |config| config.tls }
                  ^^^^^^^^^^^^^^^^^^^^^^^ `complete` builds the `Shop::Mailbox` it talks to; %{seam}
            box&.deliver(receipt)
            true
          end

          def plain = Gateway.new.charge
                      ^^^^^^^^^^^ `plain` builds the `Gateway` it talks to; %{seam}
          def save = Gateway.new(@rows).save!
                     ^^^^^^^^^^^^^^^^^^ `save` builds the `Gateway` it talks to; %{seam}
          def limit = Gateway.new(@rows).limit = 3
                      ^^^^^^^^^^^^^^^^^^ `limit` builds the `Gateway` it talks to; %{seam}
          def sweep = @rows.each { Gateway.new(it).clear }
                                   ^^^^^^^^^^^^^^^ `sweep` builds the `Gateway` it talks to; %{seam}
          def count = 3.times { Gateway.new(it).tick }
                                ^^^^^^^^^^^^^^^ `count` builds the `Gateway` it talks to; %{seam}
          def total
            Gateway.new(@key).total
            ^^^^^^^^^^^^^^^^^ `total` builds the `Gateway` it talks to; %{seam}
            rate = 1
            Mailbox.new(rate)
          end

          def checkout
            gateway = Gateway.new("live")
                      ^^^^^^^^^^^^^^^^^^^ `checkout` builds the `Gateway` it talks to; %{seam}
            gateway.charge(@cents)
            Mailbox.new(@cents)
          end
        end
      end
    RUBY
  end

  it "flags a collaborator built from what the method does not own: a constant, a global or a class variable" do
    expect_offense(<<~RUBY, seam: seam)
      class Gateway
      end

      class Checkout
        def find = Gateway.new(DB).find(@id)
                   ^^^^^^^^^^^^^^^ `find` builds the `Gateway` it talks to; %{seam}
        def log = Gateway.new(@key, out: $stderr).line
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `log` builds the `Gateway` it talks to; %{seam}
        def pool = Gateway.new(@@size).take
                   ^^^^^^^^^^^^^^^^^^^ `pool` builds the `Gateway` it talks to; %{seam}
        def url = Gateway.new(Settings::URL).host
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^ `url` builds the `Gateway` it talks to; %{seam}
      end
    RUBY
  end

  it "flags a collaborator built in a method and kept in a field" do
    expect_offense(<<~RUBY, seam: seam)
      class Gateway
      end

      class Checkout
        def gateway = @gateway ||= Gateway.new("live")
                                   ^^^^^^^^^^^^^^^^^^^ `gateway` builds the `Gateway` it keeps in `@gateway`; %{seam}
        def nesting = @nesting = Gateway.new(@node)
                                 ^^^^^^^^^^^^^^^^^^ `nesting` builds the `Gateway` it keeps in `@nesting`; %{seam}
        def shared = @@pool = Gateway.new(@size)
                              ^^^^^^^^^^^^^^^^^^ `shared` builds the `Gateway` it keeps in `@@pool`; %{seam}
        def global = $pool = Gateway.new(@size)
                             ^^^^^^^^^^^^^^^^^^ `global` builds the `Gateway` it keeps in `$pool`; %{seam}
      end
    RUBY
  end

  it "flags a collaborator built in a method and handed on as another object's dependency" do
    expect_offense(<<~RUBY, seam: seam)
      class Gateway
      end

      class Checkout
        def order = Order.new(Gateway.new("live"), @items)
                              ^^^^^^^^^^^^^^^^^^^ `order` builds the `Gateway` it hands to `Order.new`; %{seam}
        def keyed = Order.new(@items, gateway: Gateway.new(KEY))
                                               ^^^^^^^^^^^^^^^^ `keyed` builds the `Gateway` it hands to `Order.new`; %{seam}
        def wrapped = Gateway.new(Gateway.new("live"))
                                  ^^^^^^^^^^^^^^^^^^^ `wrapped` builds the `Gateway` it hands to `Gateway.new`; %{seam}
        def local
          gateway = Gateway.new
                    ^^^^^^^^^^^ `local` builds the `Gateway` it hands to `Shop::Order.new`; %{seam}
          Shop::Order.new(@items, gateway:).place
        end
      end
    RUBY
  end

  it "allows a value wrapper built from the method's own values and queried on the spot" do
    expect_no_offenses(<<~RUBY)
      class Nesting
      end

      class Checkout
        COLUMNS = %w[number date].freeze

        def qualified(node) = Nesting.new(node).qualified
        def opening = Nesting.new(@node).opening
        def charge(cents) = Nesting.new(cents, "USD").charge
        def csv = Nesting.new(COLUMNS, @rows, %w[a b]).csv
        def own = Nesting.new(self).valid? ? 1 : 0
        def names(nodes) = nodes.map { Nesting.new(it).qualified }
        def helper = Nesting.new(source.lines).size
        def invoice = Invoice.new(@cents, Nesting.new(@cents, 5_000))
        def handed
          rate = Nesting.new(@cents)
          Invoice.new(rate).total
        end
        def depth
          nesting = Nesting.new(@node)
          nesting.names.size + nesting.depth
        end
      end
    RUBY
  end

  # content-tagger: a tree node built, filled and returned; a parameter rebound to the wrapper built from it.
  it "allows the object a method builds and returns, filled on the way, and a local rebound to its wrapper" do
    expect_no_offenses(<<~RUBY)
      class Gateway
      end

      class Tree
        def parse(row)
          item = Gateway.new(row["title"])
          row["children"].each { item << parse(it) }
          item.save
          item
        end

        def check(taxon)
          taxon = Gateway.new(taxon, prefix: "/")
          Gateway.new(taxon.path).valid? && taxon.valid?
        end
      end
    RUBY
  end

  it "allows an object built to be returned, or passed to a method that is not a constructor" do
    expect_no_offenses(<<~RUBY)
      module Shop
        class Gateway
        end

        class Cart
          def with(item) = Cart.new(@items + [item])
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
          def bare = new(Gateway.new("live"))
          def lazy
            gateway ||= Gateway.new("live")
            gateway
          end
        end
      end
    RUBY
  end

  # mechanize: a form, its uploads, an auth challenge, a test response and a cookie jar, built per call and handed on.
  it "allows a value the method builds per call, fills and hands on" do
    expect_no_offenses(<<~RUBY)
      class Form
      end

      class Client
        def post(query)
          form = Form.new({ "method" => "POST" })
          query.each do |name, io|
            form.enctype = "multipart"
            upload = Form.new(name)
            upload.data = io
            form.add(upload)
          end
          @transport.submit(form)
        end

        def keyed
          form = Form.new
          form.fill(@fields)
          @transport.submit(@uri, form: form)
        end

        def listed
          form = Form.new
          form.fill(@fields)
          @transport.submit([form])
        end

        def safe
          form = Form.new
          form.fill(@fields)
          @transport&.submit(form)
        end

        def upward
          form = Form.new
          form.fill(@fields)
          super(form)
        end

        def yielded
          form = Form.new
          form.fill(@fields)
          yield form
        end

        def early
          form = Form.new
          form.fill(@fields)
          return form if @fields
          @fields
        end

        def jar(text) = Form.new.tap { |jar| jar.parse(text) }
        def tapped = Form.new.tap(&:load)
        def logged = @log.tap(Form.new).flush
      end
    RUBY
  end

  # mechanize's `click`: the message goes to the page the name held before; the new blank page is only handed on.
  it "reads a message sent before the local is rebound as the earlier value's" do
    expect_no_offenses(<<~RUBY)
      class Page
      end

      class Client
        def click(link)
          page = link.page
          page.check
          page = Page.new
          @log.count
        end

        def inline(link)
          page = link.page
          page.check; page = Page.new
          @log.count
        end
      end
    RUBY
  end

  it "still flags a collaborator talked to through tap, kept through tap, or handed on before it was built" do
    expect_offense(<<~RUBY, seam: seam)
      class Gateway
      end

      class Checkout
        def loaded = Gateway.new("live").tap { it.load }.charge
                     ^^^^^^^^^^^^^^^^^^^ `loaded` builds the `Gateway` it talks to; %{seam}
        def jar = @jar ||= Gateway.new("live").tap { it.load }
                           ^^^^^^^^^^^^^^^^^^^ `jar` builds the `Gateway` it keeps in `@jar`; %{seam}

        def renew(gateway)
          @log.write(gateway)
          gateway = Gateway.new("live")
                    ^^^^^^^^^^^^^^^^^^^ `renew` builds the `Gateway` it talks to; %{seam}
          gateway.charge
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
