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

  # unparser's memoizer restores a method's visibility through `@descendant.__send__(@original_visibility, name)`.
  it "does not advise public_send for a computed name sent to a class the code treats as one" do
    expect_offense(<<~RUBY)
      class Memo
        def initialize(host, name)
          @host = host
          @visibility = host.private_method_defined?(name) ? :private : :public
        end

        def restore = @host.__send__(@visibility, @name)
                            ^^^^^^^^ `__send__` sends a computed name to a class or module, whose private methods (`private`, `module_function`, `remove_const`) `public_send` cannot reach; let the class say it in its own body, or decorate its objects instead of changing the class from outside.
        def define(body) = target.send(@kind, @name, &body)
                                  ^^^^ `send` sends a computed name to a class or module, whose private methods (`private`, `module_function`, `remove_const`) `public_send` cannot reach; let the class say it in its own body, or decorate its objects instead of changing the class from outside.
        def defined? = target.method_defined?(@name)
        def feature(name) = Features.send(name)
                                     ^^^^ `send` sends a computed name to another object, private methods included; `public_send` keeps the dispatch to its interface.
        def plain(name) = @host.reader.send(name)
                                       ^^^^ `send` sends a computed name to another object, private methods included; `public_send` keeps the dispatch to its interface.
      end

      class Relay
        def relay(name) = @host.send(name)
                                ^^^^ `send` sends a computed name to another object, private methods included; `public_send` keeps the dispatch to its interface.
      end
    RUBY
  end

  # ahoy's `controller.send(Ahoy.user_method) if controller.respond_to?(Ahoy.user_method, true)`.
  it "does not advise public_send for a computed name the code checks among the private methods" do
    expect_offense(<<~RUBY)
      class Store
        def user
          controller.send(@method) if controller.respond_to?(@method, true)
                     ^^^^ `send` sends a computed name to another object to reach its private methods, which `public_send` cannot; send it a message it answers in public, or map the names to objects.
        end

        def visit(page)
          page.send(@method) if page.respond_to?(@method)
               ^^^^ `send` sends a computed name to another object, private methods included; `public_send` keeps the dispatch to its interface.
        end
      end
    RUBY
  end

  # strong_migrations' `WrappedConnection#send`, which Rails' schema dumper calls with private names.
  it "leaves the forward of the send an object overrides" do
    expect_no_offenses(<<~RUBY)
      class Wrapped
        def send(name, ...)
          respond_to?(name, true) ? super : @target.send(name, ...)
        end

        def __send__(name, *args) = @target.__send__(name, *args)
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
