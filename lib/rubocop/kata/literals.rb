# frozen_string_literal: true

require "prism"

class RuboCop::Kata::Literals
  include Enumerable

  PLACEHOLDER = "\0"

  def initialize(tree)
    @tree = tree
  end

  def each(&) = values(@tree).reject { it.first.empty? }.each(&)

  def unmatched(other)
    left = other.map(&:first).tally
    find { |value, _| (left[value] = left.fetch(value, 0) - 1).negative? }&.last
  end

  private

  def values(node)
    return values(node.value) if label?(node)
    return [[node.unescaped, node.location.start_line]] if node.respond_to?(:unescaped)
    return [[joined(node), node.location.start_line], *nested(node)] if composite?(node)
    node.compact_child_nodes.flat_map { values(it) }
  end

  def label?(node) = node.is_a?(Prism::AssocNode) && node.key.is_a?(Prism::SymbolNode)

  def composite?(node) = node.respond_to?(:parts)

  def joined(node) = node.parts.map { piece(it) }.join

  def piece(part)
    return part.unescaped if part.respond_to?(:unescaped)
    return joined(part) if composite?(part)
    spelled(part) || PLACEHOLDER
  end

  def nested(node) = node.parts.flat_map { inner(it) }

  def inner(part)
    return nested(part) if composite?(part)
    part.respond_to?(:unescaped) || spelled(part) ? [] : values(part)
  end

  def spelled(part)
    body = part.compact_child_nodes.first&.compact_child_nodes.to_a
    body.first.unescaped if body.one? && body.first.respond_to?(:unescaped)
  end
end
