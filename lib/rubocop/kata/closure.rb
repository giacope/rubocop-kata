# frozen_string_literal: true

class RuboCop::Kata::Closure
  def initialize(start, &step)
    @start = start
    @step = step
  end

  def to_a
    found = @start
    loop do
      called = @step.call(found)
      return found if (called - found).empty?
      found |= called
    end
  end
end
