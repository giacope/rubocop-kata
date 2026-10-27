# frozen_string_literal: true

class RuboCop::Kata::Nesting
  def initialize(node)
    @node = node
  end

  def names
    scopes = @node.each_ancestor(:class, :module).to_a.reverse
    scopes.each_with_object([]) { |scope, found| found << joined(found.last, scope.identifier) }.reverse
  end

  def qualified = joined(names.first, @node.identifier)

  def candidates(name) = [*names.map { "#{it}::#{name}" }, name]

  private

  def joined(outer, identifier)
    identifier.absolute? ? identifier.const_name : [*outer, identifier.const_name].join("::")
  end
end
