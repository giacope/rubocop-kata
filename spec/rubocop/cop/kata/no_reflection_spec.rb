# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::NoReflection, :config) do
  let(:ruby_version) { 3.4 }

  it "flags reaching into another object's fields" do
    expect_offense(<<~RUBY)
      class Receipt
        def total = @order.instance_variable_get(:@total)
                           ^^^^^^^^^^^^^^^^^^^^^ `instance_variable_get` reaches into another object's fields; ask it for what you need through a method it exposes.
        def peek(other) = other&.instance_variable_set(:@page, @page)
                                 ^^^^^^^^^^^^^^^^^^^^^ `instance_variable_set` reaches into another object's fields; ask it for what you need through a method it exposes.
      end
    RUBY
  end

  it "flags calling a named method past another object's interface" do
    expect_offense(<<~RUBY)
      class Export
        def secret = @record.send(:token)
                             ^^^^ `send` calls `token` past another object's interface; send it a message it answers in public.
        def other = @record.__send__("digest", 1)
                            ^^^^^^^^ `__send__` calls `digest` past another object's interface; send it a message it answers in public.
      end
    RUBY
  end

  # ahoy's `controller.send(Ahoy.user_method)`, mechanize's `servlet.send "do_#{req.method}"`: Style/Send's sites.
  it "flags a computed name sent past another object's interface with send" do
    expect_offense(<<~RUBY)
      class Store
        def user(controller) = controller.send(@method)
                                          ^^^^ `send` sends a computed name to another object, private methods included; `public_send` keeps the dispatch to its interface.
        def dispatch(servlet) = servlet.__send__("do_\#{@verb}", @request)
                                        ^^^^^^^^ `__send__` sends a computed name to another object, private methods included; `public_send` keeps the dispatch to its interface.
      end
    RUBY
  end

  it "flags a constant name built at run time" do
    expect_offense(<<~RUBY)
      class Export
        def view = Object.const_get("Shop::\#{@kind}View").new(@record)
                          ^^^^^^^^^ `const_get` builds a constant's name at run time, hidden coupling; map the names to objects, or inject one.
        def other = "Shop::\#{@kind}".constantize
                                     ^^^^^^^^^^^ `constantize` builds a constant's name at run time, hidden coupling; map the names to objects, or inject one.
      end
    RUBY
  end

  it "allows reflection on itself, dispatch on a name it is handed, and the boot layer" do
    expect_no_offenses(<<~RUBY)
      class Export
        def row = @fields.map { |field| @record.public_send(field) }
        def mine = instance_variable_get(:@total)
        def own = self.send(:secret)
        def name = send(:secret)
        def dynamic = @record.public_send(@name)
        def computed = send("do_\#{@verb}")
        def fixed = Object.const_get("Shop::View")
        def seam(kind = Object.const_get("Shop::\#{KIND}")) = kind
        def bare = @record.send
      end
      Object.const_get("Shop::\#{ENV.fetch("KIND")}")
    RUBY
  end
end
