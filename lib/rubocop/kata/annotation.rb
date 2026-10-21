# frozen_string_literal: true

class RuboCop::Kata::Annotation
  extend RuboCop::AST::NodePattern::Macros

  TYPES = /\AT(::|\z)/

  def_node_matcher :wrapped, "(send (const {nil? cbase} :T) {:let :cast :must :unsafe :bind} $_ ...)"

  def initialize(node)
    @node = node
  end

  def value
    found = @node
    found = wrapped(found) while wrapped(found)
    found
  end

  def wrapper? = !wrapped(@node).nil?

  def typing?
    link = @node
    link = link.receiver while link&.send_type?
    TYPES.match?(link&.const_name)
  end
end
