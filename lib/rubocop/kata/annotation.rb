# frozen_string_literal: true

class RuboCop::Kata::Annotation
  WRAPPERS = %i[let cast must unsafe bind].freeze
  TYPES = /\AT(::|\z)/

  def initialize(node)
    @node = node
  end

  def value
    found = @node
    found = found.first_argument while self.class.new(found).wrapper?
    found
  end

  def wrapper? = typing? && @node.receiver.const_type? && WRAPPERS.include?(@node.method_name) && @node.arguments?

  def typing?
    link = @node
    link = link.receiver while link&.send_type?
    !link.equal?(@node) && link&.const_type? && TYPES.match?(link.const_name)
  end
end
