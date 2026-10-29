# frozen_string_literal: true

class RuboCop::Kata::Kin
  def initialize(parents = [], methods = {}, superclass = [])
    @parents = parents
    @methods = methods
    @superclass = superclass
  end

  def +(other) = other.joined(@parents, @methods, @superclass)

  def defines?(method) = @methods.key?(method)

  def calls(names) = @methods.slice(*names).values.flatten

  def parents(known) = @parents.map { |written, nesting| resolved(written, nesting, known) }

  def superclass(known) = @superclass.empty? ? [] : [resolved(*@superclass, known)]

  protected

  def joined(parents, methods, superclass)
    merged = methods.merge(@methods) { |_, mine, theirs| mine | theirs }
    self.class.new(parents | @parents, merged, superclass.empty? ? @superclass : superclass)
  end

  private

  def resolved(written, nesting, known)
    return written.delete_prefix("::") if written.start_with?("::")
    candidates = nesting.reverse.map { "#{it}::#{written}" } << written
    candidates.find { known.key?(it) } || written
  end
end
