# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::NoHardWiring, :config) do
  let(:ruby_version) { 3.4 }
  let(:cop_config) { { "OwnedPaths" => [], "RootSuperclasses" => ["RuboCop::Cop::Base"] } }

  def seam = "take one in the constructor, with this `new` as the parameter's default."

  def built(home, method)
    "`#{home}` cannot take one in a constructor (a framework builds it past `initialize`, or it is mixed in): " \
      "take one as a parameter of `#{method}`, with this `new` as its default, or build it where `#{home}` is used."
  end

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
            box = Shop::Mailbox.new { |config| config.tls }
                  ^^^^^^^^^^^^^^^^^ `complete` builds the `Shop::Mailbox` it talks to; %{seam}
            box&.deliver(receipt)
            true
          end

          def plain = Gateway.new.charge
                      ^^^^^^^^^^^ `plain` builds the `Gateway` it talks to; %{seam}
          def save = Gateway.new(KEY).save!
                     ^^^^^^^^^^^^^^^^ `save` builds the `Gateway` it talks to; %{seam}
          def sweep = @rows.each { Gateway.new("live").clear(it) }
                                   ^^^^^^^^^^^^^^^^^^^ `sweep` builds the `Gateway` it talks to; %{seam}

          def fetch
            client = Gateway.new
                     ^^^^^^^^^^^ `fetch` builds the `Gateway` it talks to; %{seam}
            client.fetch(@url)
          end

          def configured
            buffer = Gateway.new("utf-8")
                     ^^^^^^^^^^^^^^^^^^^^ `configured` builds the `Gateway` it talks to; %{seam}
            buffer.write(@text)
            buffer.content
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

  # R6B5-K2: a constructor called through `&.` is the same constructor.
  it "reads a constructor called through safe navigation as the one it is handed to" do
    expect_offense(<<~RUBY, seam: seam)
      class Gateway
      end

      class Checkout
        def order = @orders&.new(Gateway.new("live"), @items)
                                 ^^^^^^^^^^^^^^^^^^^ `order` builds the `Gateway` it hands to `@orders.new`; %{seam}
        def local
          gateway = Gateway.new
                    ^^^^^^^^^^^ `local` builds the `Gateway` it hands to `@orders.new`; %{seam}
          @orders&.new(@items, gateway:).place
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

  # transition's entries built per row and saved or collected; support's `Paths` record saved and read back.
  it "allows an object built from the method's own inputs and dropped or returned, whatever the method does to it" do
    expect_no_offenses(<<~RUBY)
      module Shop
        class Gateway
        end

        class Batch
          def complete
            box = Shop::Mailbox.new(host) { |config| config.tls }
            box&.deliver(receipt)
            true
          end

          def save = Gateway.new(@rows).save!
          def limit = Gateway.new(@rows).limit = 3
          def sweep = @rows.each { Gateway.new(it).clear }
          def count = 3.times { Gateway.new(it).tick }
          def total
            Gateway.new(@key).total
            @key
          end

          def entries
            records = @paths.map do |path|
              entry = Gateway.new(path:)
              entry.batch = self
              entry
            end
            Gateway.import(records)
          end

          def import
            @rows.each do |row|
              entry = Gateway.new(path: row.path)
              entry.batch = self
              entry.save!
            end
          end

          def redirect
            saved = Gateway.new(paths)
            saved.save
            saved.id
          end
        end
      end
    RUBY
  end

  # unparser's `Buffer`: built empty, filled through the writer it is handed to (or by the method), read back.
  it "allows an empty object the call fills and reads back" do
    expect_no_offenses(<<~RUBY)
      class Buffer
      end

      class Writer
      end

      class Source
        def render(take)
          buffer = Buffer.new
          Writer.new(buffer:, parts: @parts.take(take)).emit
          buffer.content
        end

        def heredoc
          buffer = Buffer.new
          writer = Writer.new(buffer, @node)
          writer.emit
          buffer.flush
          buffer.content
        end

        def round_trips?(source)
          buffer = Buffer.new
          buffer.write(source)
          @node.eql?(parse(buffer.content), @strict)
        end

        def encoded(source)
          buffer = Buffer.new
          buffer.write!(source) if source
          buffer.content
        end

        def lines
          buffer = Buffer.new
          @rows.each { buffer.write(it) }
          @rows.map { buffer.line(it) }
        end

        def rows
          @paths.map do |path|
            row = Buffer.new
            row.path = path
            row
          end
        end

        def last
          row = Buffer.new
          row.path = @path
          @paths.map { row }
        end
      end
    RUBY
  end

  it "still flags an empty object asked before anything filled it" do
    expect_offense(<<~RUBY, seam: seam)
      class Buffer
      end

      class Source
        def status
          buffer = Buffer.new
                   ^^^^^^^^^^ `status` builds the `Buffer` it talks to; %{seam}
          size = buffer.size; buffer.clear!
          size
        end
      end
    RUBY
  end

  # searchkick's `Results.new(nil, nil, nil).respond_to?(...)` in `respond_to_missing?`.
  it "allows a prototype asked what its class answers" do
    expect_no_offenses(<<~RUBY)
      class Results
      end

      class Relation
        def respond_to_missing?(...) = Results.new(nil, nil).respond_to?(...) || super
        def reader(name) = Results.new.method(name)
      end
    RUBY
  end

  it "flags an object kept through a local, and a value handed into an object the method keeps" do
    expect_offense(<<~RUBY, seam: seam)
      class Gateway
      end

      class Order
      end

      class Checkout
        def gateway
          gateway = Gateway.new(@key)
                    ^^^^^^^^^^^^^^^^^ `gateway` builds the `Gateway` it keeps in `@gateway`; %{seam}
          gateway.load
          @gateway = gateway
        end

        def pool
          pool = Gateway.new(@size)
                 ^^^^^^^^^^^^^^^^^^ `pool` builds the `Gateway` it keeps in `@@pool`; %{seam}
          @@pool ||= pool
        end

        def log = @log ||= Logger.new(Gateway.new(@key))
                                      ^^^^^^^^^^^^^^^^^ `log` builds the `Gateway` it hands to `Logger.new`; %{seam}

        def client
          options = Gateway.new(@url)
                    ^^^^^^^^^^^^^^^^^ `client` builds the `Gateway` it hands to `Faraday.new`; %{seam}
          connection = Faraday.new(options)
          $connection = connection
        end

        def attempt
          pace = Gateway.new(@timings)
                 ^^^^^^^^^^^^^^^^^^^^^ `attempt` builds the `Gateway` it hands to `Memory.new`; %{seam}
          @attempt ||= Attempt.new(killers: Memory.new(pace))
        end

        def order = @order = Order.new(Gateway.new(@key))
                             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `order` builds the `Order` it keeps in `@order`; %{seam}
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

        def blank(link)
          page = link.page
          page.check
          page = Page.new("about:blank")
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

  # hashira's Sites#each and Clones (fp/hashira-3), savon's SerializedInput#content (fp/twin-savon-1), alba's
  # InstanceMethods#as_json (fp/twin-alba-4): a type applied to the method's inputs makes the input's value.
  it "allows an object built from a class or module applied to the method's own inputs" do
    expect_no_offenses(<<~RUBY)
      module Demo
        class Body
        end

        class Owner
        end

        module Words
          def self.key(word) = word.downcase
        end

        class Sites
          def each(&)
            @types.each do |type, full|
              Demo::Body.new(type, Demo::Owner.new(full)).each(&)
            end
          end

          def joined(&) = Dir.children(@root).each { |fixture| Body.new(File.join(fixture, "project"), fixture).each(&) }
          def computed(part) = Body.new(@message[Words.key(part)]).to_s
          def one(value) = Body.new(@key, Owner.of(@meta)).json(value)
          def parsed = Body.new(JSON.parse(@text), URI.parse(@url)).to_s
          def nested(part) = Body.new(Owner.new(Words.key(part))).to_s
          def acronym(part) = Body.new(SQL.quote(part)).to_s
        end

        module SQL
        end
      end
    RUBY
  end

  it "still flags an object built from a type applied to nothing, to literals, or from a value constant" do
    expect_offense(<<~RUBY, seam: seam)
      module Demo
        class Body
        end

        class Owner
        end

        class Sites
          def clock = Body.new(@key, Clock.now).stamp
                      ^^^^^^^^^^^^^^^^^^^^^^^^^ `clock` builds the `Body` it talks to; %{seam}
          def live = Body.new(@key, Settings.for(:live)).charge
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `live` builds the `Body` it talks to; %{seam}
          def env = Body.new(ENV.fetch(@key)).read
                    ^^^^^^^^^^^^^^^^^^^^^^^^^ `env` builds the `Body` it talks to; %{seam}
          def pool = Body.new(DB.pool(@name)).find
                     ^^^^^^^^^^^^^^^^^^^^^^^^ `pool` builds the `Body` it talks to; %{seam}
          def wired = Body.new(@key, Owner.new(DB)).each
                                     ^^^^^^^^^^^^^ `wired` builds the `Owner` it hands to `Body.new`; %{seam}
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `wired` builds the `Body` it talks to; %{seam}
          def read = Body.new(@key, Owner::LIMIT.call(@key)).each
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `read` builds the `Body` it talks to; %{seam}
        end
      end
    RUBY
  end

  # alba's ClassMethods#layout (fp/twin-alba-1) and faraday's MiddlewareRegistry (fp/twin-faraday-3): the methods of a
  # module a class extends are its class methods, where objects are wired.
  it "allows a module a class extends, whose methods are class methods" do
    expect_no_offenses(<<~RUBY)
      module Shelf
        class Label
        end

        def self.included(base)
          super
          base.extend(Macros)
        end

        module ClassMethods
          def label(text) = @_label = Label.new(text)
        end

        module Macros
          def layout(file:) = @_layout = Label.new(file)
        end
      end

      module Http
        class Catalog
        end

        module Registry
          def lookup(key) = catalog.lookup(key)

          private

          def catalog = @_catalog ||= Catalog.new(self)
        end

        class Adapter
          extend Registry
        end

        module Stack
          def stack = @_stack ||= Catalog.new(self)
        end

        Request = Class.new
        Request.extend(Stack)
      end

      module Tracked
        extend ActiveSupport::Concern

        class_methods do
          def tracker = @_tracker ||= Shelf::Label.new(name)
        end
      end
    RUBY
  end

  it "still judges a module's included block, a class named ClassMethods, and a method outside every class" do
    expect_offense(<<~RUBY, seam: seam)
      class Label
      end

      module Tracked
        extend ActiveSupport::Concern

        included do
          def tracker = @_tracker ||= Label.new(name)
                                      ^^^^^^^^^^^^^^^ `tracker` builds the `Label` it keeps in `@_tracker`; %{seam}
        end
      end

      class ClassMethods
        def label = Label.new.to_s.upcase
                    ^^^^^^^^^ `label` builds the `Label` it talks to; %{seam}
      end

      def label = Label.new.to_s.upcase
                  ^^^^^^^^^ `label` builds the `Label` it talks to; %{seam}
    RUBY
  end

  it "still judges a module included into a class, or extended into an object" do
    expect_offense(<<~RUBY, registry: built("Http::Registry", "catalog"), decor: built("Http::Decor", "decorated"))
      module Http
        class Catalog
        end

        module Registry
          def catalog = @_catalog ||= Catalog.new(self)
                                      ^^^^^^^^^^^^^^^^^ `catalog` builds the `Catalog` it keeps in `@_catalog`; %{registry}
        end

        class Adapter
          include Registry

          def wrap(user) = user.extend(Decor)
        end

        module Decor
          def decorated = @_decorated ||= Catalog.new(self)
                                          ^^^^^^^^^^^^^^^^^ `decorated` builds the `Catalog` it keeps in `@_decorated`; %{decor}
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

  it "judges a module's instance methods too, with the seam a module has" do
    expect_offense(<<~RUBY, built: built("Billing", "charge"))
      class Gateway
      end

      module Billing
        def charge = Gateway.new.charge
                     ^^^^^^^^^^^ `charge` builds the `Gateway` it talks to; %{built}
      end
    RUBY
  end

  # hashira's `Options = Data.define(...) do def pipeline ... end` inside `module Hashira::CLI`.
  it "keeps the constructor seam for a class a module's block defines" do
    expect_offense(<<~RUBY, seam: seam)
      class Notices
      end

      module Cli
        Options = Data.define(:mode) do
          def pipeline = Notices.new.scanning(mode)
                         ^^^^^^^^^^^ `pipeline` builds the `Notices` it talks to; %{seam}
        end
      end
    RUBY
  end

  # collections-publisher's Tag and LinkReport: ActiveRecord allocates a loaded record past `initialize`.
  it "gives a model its framework builds the seam it has, a method parameter" do
    expect_offense(<<~RUBY, built: built("Tag", "tagged_documents"), report: built("LinkReport", "links"))
      class TaggedDocuments
      end

      class Tag < ApplicationRecord
        def tagged_documents
          @tagged_documents ||= TaggedDocuments.new(self)
                                ^^^^^^^^^^^^^^^^^^^^^^^^^ `tagged_documents` builds the `TaggedDocuments` it keeps in `@tagged_documents`; %{built}
        end
      end

      class Record < ActiveRecord::Base
      end

      class LinkReport < Record
        def links = TaggedDocuments.new.all_paths(@step)
                    ^^^^^^^^^^^^^^^^^^^ `links` builds the `TaggedDocuments` it talks to; %{report}
      end
    RUBY
  end

  it "keeps the constructor seam for a class the project builds" do
    expect_offense(<<~RUBY, seam: seam)
      class TaggedDocuments
      end

      class Tag < Struct
        def tagged_documents = @tagged_documents ||= TaggedDocuments.new(self)
                                                     ^^^^^^^^^^^^^^^^^^^^^^^^^ `tagged_documents` builds the `TaggedDocuments` it keeps in `@tagged_documents`; %{seam}
      end
    RUBY
  end

  # mechanize's Minitest test case and ahoy's controller mixin: composition roots a framework builds.
  it "allows the test classes and the modules a load hook mixes into a framework's root class" do
    cop_config.delete("RootSuperclasses")
    expect_no_offenses(<<~RUBY)
      class Tracker
      end

      class TestCase < Minitest::Test
        def setup = @tracker = Tracker.new(nil)
      end

      class RailsCase < ActiveSupport::TestCase
        def setup = @tracker = Tracker.new(nil)
      end

      module Tracking
        def tracker = @tracker ||= Tracker.new(self)
      end

      ActiveSupport.on_load(:action_controller) do
        include Tracking
      end
    RUBY
  end

  it "still judges a module a load hook mixes into a model" do
    expect_offense(<<~RUBY, built: built("Visits", "visit"))
      class Tracker
      end

      module Visits
        def visit = @visit ||= Tracker.new(self)
                               ^^^^^^^^^^^^^^^^^ `visit` builds the `Tracker` it keeps in `@visit`; %{built}
      end

      ActiveSupport.on_load(:active_record) { include Visits }
    RUBY
  end

  context "with the project's other files" do
    include TabledCop

    let(:root) { Dir.mktmpdir("kata-wiring") }
    let(:cop) do
      shipped = RuboCop::ConfigLoader.default_configuration.for_cop("Kata/NoHardWiring")
      wiring = { "Kata/NoHardWiring" => shipped.merge("OwnedPaths" => ["lib/**/*.rb"]) }
      described_class.new(RuboCop::Config.new(wiring, File.join(root, ".rubocop.yml")))
    end

    before do
      FileUtils.mkdir_p(File.join(root, "lib", "demo"))
      hook = "ActiveSupport.on_load(:action_controller) { include Demo::Controller }\n"
      File.write(File.join(root, "lib", "demo.rb"), hook)
      File.write(File.join(root, "lib", "demo", "tracker.rb"), "class Demo::Tracker\nend\n")
    end

    after { FileUtils.rm_rf(root) }

    it "reads a module another file's class extends as class-level" do
      request = "module Demo\n  class Request\n    extend Registry\n  end\nend\n"
      File.write(File.join(root, "lib", "demo", "request.rb"), request)
      registry = "module Demo\n  module Registry\n    def catalog = @catalog ||= Demo::Tracker.new(self)\n  end\nend\n"
      other = "module Demo\n  module Visits\n    def catalog = @catalog ||= Demo::Tracker.new(self)\n  end\nend\n"
      expect([offenses(registry), offenses(other).map(&:line)]).to(eq([[], [3]]))
    end

    it "reads the load hooks in the project's other files" do
      mixin = "module Demo::Controller\n  def ahoy = @ahoy ||= Demo::Tracker.new(self)\nend\n"
      other = "module Demo::Visits\n  def ahoy = @ahoy ||= Demo::Tracker.new(self)\nend\n"
      expect([offenses(mixin), offenses(other).map(&:line)]).to(eq([[], [2]]))
    end
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
