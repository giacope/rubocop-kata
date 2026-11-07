# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::NoMonkeyPatch, :config) do
  let(:ruby_version) { 3.4 }
  let(:cop_config) do
    RuboCop::ConfigLoader.default_configuration.for_cop("Kata/NoMonkeyPatch").merge("Enabled" => true)
  end
  let(:advice) { "for every caller; use a refinement (`refine %s`) or a decorator object." }

  def patch(label, target) = "`#{label}` patches `#{target}` #{format(advice, target)}"

  it "reports a core class changed from outside by a mixin or an evaluated body" do
    expect_offense(<<~RUBY)
      Integer.class_eval do
      ^^^^^^^^^^^^^^^^^^ #{patch("Integer.class_eval", "Integer")}
        def cents = format("%.2f", self / 100.0)
      end
      String.include(Shop::Slugs)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{patch("String.include", "String")}
      Hash.prepend(Shop::Deep)
      ^^^^^^^^^^^^^^^^^^^^^^^^ #{patch("Hash.prepend", "Hash")}
      ::Object.extend(Shop::Missing)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{patch("::Object.extend", "Object")}
    RUBY
  end

  it "reports a library's class patched the same ways, and through send" do
    expect_offense(<<~RUBY)
      ::ActiveRecord::Base.prepend(SaveWithBulletSupport)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{patch("::ActiveRecord::Base.prepend", "ActiveRecord::Base")}
      Object.send(:include, Delayed::MessageSending)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{patch("Object.send(:include)", "Object")}
      Net::HTTP.__send__(:define_method, :request_with_timing) { |*args| args }
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{patch("Net::HTTP.__send__(:define_method)", "Net::HTTP")}
      Rails::Rack::Logger.class_eval do
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{patch("Rails::Rack::Logger.class_eval", "Rails::Rack::Logger")}
        alias_method :old_call, :call
      end
      Mail::Message.class_eval <<~CODE
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{patch("Mail::Message.class_eval", "Mail::Message")}
        def deliver = 1
      CODE
      String.define_method(:shout) { upcase }
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{patch("String.define_method", "String")}
      String.singleton_class.prepend(Shop::Parsing)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{patch("String.singleton_class.prepend", "String")}
      class << Time
      ^^^^^^^^^^^^^ #{patch("class << Time", "Time")}
        def frozen_now = now
      end
    RUBY
  end

  it "passes the hooks, extension points and refinements that change no class from outside" do
    expect_no_offenses(<<~RUBY)
      module Shop
        module Slugs
          def self.included(base)
            base.extend(ClassMethods)
          end

          refine String do
            def to_slug = downcase
          end
        end
      end
      ActiveSupport.on_load(:active_record) { extend Shop::Slugs }
      ActiveSupport.on_load(:action_controller_base) do
        ActionController::Base.extend(Shop::Responders)
      end
      Integer.class_eval { @count }
      String.include?("a")
      Struct.new(:name) do
        def label = name
      end
      [String, Symbol].each { |kind| kind.include(Shop::Slugs) }
      Hash.instance_eval <<~CODE
        @x
      CODE
      Object.send(:new)
      XPath.attr(:id)
      Object.send(name, Shop::Slugs)
      class << String
      end
      class << self
        def shout = 1
      end
      Hash.class_eval { other.include(Shop::Slugs) }
    RUBY
  end

  it "reports a class an on_load hook does not name, patched inside that hook" do
    expect_offense(<<~RUBY)
      ActiveSupport.on_load(:active_record) do
        ActiveRecord::Migration.prepend(Shop::Checks)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{patch("ActiveRecord::Migration.prepend", "ActiveRecord::Migration")}
        ActiveRecord::Base.extend(Shop::Slugs)
      end
      ActiveSupport.on_load(:mongoid) { Mongoid::Document::ClassMethods.include(Shop::Model) }
                                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{patch("Mongoid::Document::ClassMethods.include", "Mongoid::Document::ClassMethods")}
      ActiveSupport.on_load(:action_mailer) { ActionMailer::Base.extend(Shop::Delay) }
      ActiveSupport.on_load(hook) { ActionMailer::Base.extend(Shop::Delay) }
                                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{patch("ActionMailer::Base.extend", "ActionMailer::Base")}
    RUBY
  end

  it "reads a plain string of code, and a definer inside a singleton class" do
    expect_offense(<<~RUBY)
      Mail::Message.class_eval("def deliver = 1")
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{patch("Mail::Message.class_eval", "Mail::Message")}
      Mail::Message.class_eval("def \#{name} = 1")
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{patch("Mail::Message.class_eval", "Mail::Message")}
      class << Time
      ^^^^^^^^^^^^^ #{patch("class << Time", "Time")}
        attr_accessor :zone
      end
    RUBY
  end

  it "passes Ruby's fork hook: a module the file defines with only _fork, prepended to Process.singleton_class" do
    expect_no_offenses(<<~RUBY)
      module Shop
        class Runtime
          module Forks
            def _fork
              super.tap { |pid| reset if pid.zero? }
            end
          end

          Spawns = Module.new do
            def _fork = super
          end
        end
      end
      Process.singleton_class.prepend(Shop::Runtime::Forks) unless Process.singleton_class < Shop::Runtime::Forks
      ::Process.singleton_class.prepend(Shop::Runtime::Spawns, Shop::Runtime::Forks)
      module Shop
        class Runtime
          Process.singleton_class.prepend(Forks)
        end
      end
    RUBY
  end

  it "still reports a prepend onto Process of a module with other methods, one it cannot see, or no hook" do
    label = "Process.singleton_class.prepend"
    expect_offense(<<~RUBY)
      module Spawning
        def _fork = super

        def spawn(*) = super
      end
      module Hooked
        include Spawning

        def _fork = super
      end
      Empty = Module.new
      Blank = Module.new {}
      module Shop
        module Spawning
        end
      end
      Hooks = Class.new do
        def _fork = super
      end
      module Hooks
      end
      module Twice
        def _fork = super

        def _fork = super
      end
      Process.singleton_class.prepend(Spawning)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{patch(label, "Process")}
      Process.singleton_class.prepend(Hooked)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{patch(label, "Process")}
      Process.singleton_class.prepend(Unseen)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{patch(label, "Process")}
      Process.singleton_class.prepend(Empty)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{patch(label, "Process")}
      Process.singleton_class.prepend(Blank)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{patch(label, "Process")}
      Process.singleton_class.prepend(Hooks)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{patch(label, "Process")}
      Process.singleton_class.prepend(Twice)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{patch(label, "Process")}
      Process.singleton_class.prepend(Forks.hook)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{patch(label, "Process")}
      Process.singleton_class.prepend
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{patch(label, "Process")}
      Process.singleton_class.include(Forks)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{patch("Process.singleton_class.include", "Process")}
      Process.prepend(Forks)
      ^^^^^^^^^^^^^^^^^^^^^^ #{patch("Process.prepend", "Process")}
      Kernel.singleton_class.prepend(Forks)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{patch("Kernel.singleton_class.prepend", "Kernel")}
      module Forks
        def _fork = super
      end
    RUBY
  end

  context "with the project's own classes" do
    include ProjectFiles

    let(:setting) { { "Kata/NoMonkeyPatch" => cop_config.merge("OwnedPaths" => ["lib/**/*.rb"]) } }

    it "leaves a class the project owns to the project" do
      files = {
        "lib/shop/order.rb" => "module Shop\n  class Order\n  end\nend\n",
        "lib/shop/audit.rb" => <<~RUBY
          module Shop
            Order.include(Audit)
            Order.class_eval { def audited = true }
          end
          Shop::Order.prepend(Shop::Audit)
          String.include(Shop::Audit)
        RUBY
      }
      expect(project_offenses(files, "lib/shop/audit.rb").map(&:line)).to(eq([6]))
    end

    it "reads a fork hook the project defines in another file by what it defines there" do
      files = {
        "lib/shop/forks.rb" => "module Shop\n  module Forks\n    def _fork = super\n  end\nend\n",
        "lib/shop/spawns.rb" => "module Shop\n  module Spawns\n    def _fork = super\n    def spawn = 1\n  end\nend\n",
        "lib/shop/loose.rb" => "def _fork = super\n",
        "lib/shop/boot.rb" => <<~RUBY
          Process.singleton_class.prepend(Shop::Forks)
          Process.singleton_class.prepend(Shop::Spawns)
        RUBY
      }
      expect(project_offenses(files, "lib/shop/boot.rb").map(&:line)).to(eq([2]))
    end
  end
end
