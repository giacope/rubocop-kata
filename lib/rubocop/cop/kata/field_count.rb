# frozen_string_literal: true

class RuboCop::Cop::Kata::FieldCount < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Memoization
  include RuboCop::Cop::Kata::Exposure
  include RuboCop::Cop::Kata::Census

  MSG = "`%s` encapsulates %d fields (%s); keep at most %d, and group the rest into an object of their own."
  MACROS = %i[attr_reader attr_writer attr_accessor attr].freeze
  SCOPES = %i[class module sclass defs].freeze

  def on_class(node) = census(node, (assigned(node) + minted(node)).uniq, MSG)

  private

  def assigned(node)
    node.each_descendant(:ivasgn).select { mine?(it, node) && !memoized?(it) }.map { it.children.first }
  end

  def minted(node) = named(node, MACROS).map { :"@#{it}" }

  def mine?(field, node)
    field.each_ancestor(:def).any? && field.each_ancestor(*SCOPES).first.equal?(node)
  end
end
