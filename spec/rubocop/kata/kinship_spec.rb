# frozen_string_literal: true

RSpec.describe(RuboCop::Kata::Kinship) do
  def records(source) = described_class.parse(source).hooks

  it "names each module a load hook mixes into the framework's class" do
    source = <<~RUBY
      ActiveSupport.on_load(:action_controller) do
        include Ahoy::Controller
        prepend ::Ahoy::Tracking, Ahoy::Logging
      end
      ActiveSupport.on_load(:action_view) { include Ahoy::Helper }
    RUBY
    expected = [
      ["Ahoy::Controller", "action_controller"], ["Ahoy::Tracking", "action_controller"],
      ["Ahoy::Logging", "action_controller"], ["Ahoy::Helper", "action_view"]
    ]
    expect(records(source)).to(eq(expected))
  end

  it "reads the innermost hook, and only a mixin into the hook's own class" do
    source = <<~RUBY
      ActiveSupport.on_load(:active_record) do
        extend Ahoy::Model
        Mongoid::Document::ClassMethods.include(Ahoy::Model)
        include
        ActiveSupport.on_load(:action_mailer) { include Ahoy::Mail }
        include Ahoy::Record
      end
    RUBY
    expect(records(source)).to(eq([["Ahoy::Mail", "action_mailer"], ["Ahoy::Record", "active_record"]]))
  end

  it "reads no hook outside a hook's block, without a block, named by a string, or another call's block" do
    source = <<~RUBY
      include Ahoy::Top
      ActiveSupport.on_load(:action_controller, &setup)
      ActiveSupport.on_load("action_view") { include Ahoy::Helper }
      configure(:action_controller) { include Ahoy::Settings }
      class Ahoy::Engine
        include Ahoy::Inner
      end
    RUBY
    expect(records(source)).to(be_empty)
  end

  # sshkit's `def_delegators :output, :log, :warn, ...`: a class answers what it delegates, aliases and reads (R6B6-K3).
  it "records the methods a class body delegates, aliases or reads, a singleton class's on the class side" do
    source = <<~RUBY
      class Abstract
        extend Logging
        extend self
        Registry.extend(Tracking)
        def_delegators :@output, :warn, :debug
        def_delegator :@output, :info, :note
        def_single_delegator :@output, :fatal
        delegate :size, to: :rows, prefix: true
        delegate :name, to: :owner, prefix: :shelf
        delegate :count, **TARGET
        alias_method :print, :emit
        alias p show
        attr_accessor :level

        class << self
          attr_reader :root
          def load = 1

          class Row
            def size = 1
          end
        end

        class << @registry
          def clear = 1
        end

        def build
          delegate :total, to: :rows
          attr_reader :depth
        end
      end
    RUBY
    found = described_class.parse(source).records
    expected = %w[warn debug note self.fatal rows_size shelf_name count print p level level= self.root self.load build]
    held = [found.fetch("Abstract")[:methods].keys.compact, found.dig("Abstract::Row", :methods).keys.compact]
    expect([*held, found.dig("#<Class:Abstract>", :parents)]).to(eq([expected, %w[size], [["Logging", []]]]))
  end
end
