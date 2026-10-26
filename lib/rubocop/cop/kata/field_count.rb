# frozen_string_literal: true

class RuboCop::Cop::Kata::FieldCount < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Memoization
  include RuboCop::Cop::Kata::Tally

  MSG = "`%s` encapsulates %d fields (%s); keep at most %d, and group the rest into an object of their own."
  MACROS = %i[attr_reader attr_writer attr_accessor attr].freeze
  SCOPES = %i[class module sclass defs].freeze

  def on_class(node)
    found = fields(node)
    most = cop_config.fetch("Max", 4)
    return if found.size <= most
    add_offense(node.loc.name, message: format(MSG, node.identifier.short_name, found.size, joined(found), most))
  end

  private

  def fields(node) = (assigned(node) + minted(node)).uniq.map { "`#{it}`" }

  def assigned(node)
    node.each_descendant(:ivasgn).select { mine?(it, node) && !memoized?(it) }.map { it.children.first }
  end

  def minted(node) = macros(node).flat_map { |call| call.arguments.select(&:sym_type?).map { :"@#{it.value}" } }

  def mine?(field, node)
    field.each_ancestor(:def).any? && field.each_ancestor(*SCOPES).first.equal?(node)
  end

  def macros(node)
    body = node.body
    statements = body&.begin_type? ? body.children : [body].compact
    statements.select { it.send_type? && it.receiver.nil? && MACROS.include?(it.method_name) }
  end
end
