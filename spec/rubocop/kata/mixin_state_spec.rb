# frozen_string_literal: true

RSpec.describe(RuboCop::Kata::MixinState) do
  include TabledCop

  let(:cop) { RuboCop::Cop::ThreadSafety::ClassInstanceVariable.new(RuboCop::Config.new) }

  # bullet prepends a `Module.new` to ActiveRecord's JoinDependency from `def self.enable`.
  it "reads a field of a module built and mixed into a class as the field of its objects" do
    source = <<~RUBY
      module Patches
        def self.enable
          ::Join.prepend(
            Module.new do
              def instantiate(rows)
                @loaded = {}
                rows.each { |row| @loaded[row] = instance_variable_get(:@seen) }
              end

              def loaded = @loaded
            end
          )
          Join.include(::Module.new { def seen = @seen })
        end
      end
    RUBY
    expect(offenses(source)).to(be_empty)
  end

  it "still reports a module extended onto a class, a singleton's mixin and a module's own methods" do
    source = <<~RUBY
      module Patches
        def self.enable
          Base.extend(Module.new { def find = @found })
          Warning.singleton_class.prepend(Module.new { def warn = @quiet })
          Join.prepend(Module.new { def self.mode = @mode })
          mixin = Module.new { def name = @name }
          Join.prepend(mixin)
          @enabled = true
        end
      end
    RUBY
    expect(offenses(source).map(&:line)).to(eq([3, 4, 5, 6, 8]))
  end
end
