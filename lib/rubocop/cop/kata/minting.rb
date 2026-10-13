# frozen_string_literal: true

module RuboCop::Cop::Kata::Minting
  extend RuboCop::AST::NodePattern::Macros

  MINTERS = %i[attr attr_reader attr_writer attr_accessor define_method define_singleton_method alias_method].freeze
  SINGLE = %i[define_method define_singleton_method alias_method].freeze

  def_node_matcher :local?, "(send {nil? self} ...)"

  def on_send(node)
    return unless local?(node)
    names = node.arguments
    names = names.first(1) if SINGLE.include?(node.method_name)
    names.select { it.type?(:sym, :str) }.each { mint(it.source_range, it.value.to_sym) }
  end

  def on_alias(node)
    name = node.new_identifier
    mint(name.source_range, name.value) if name.sym_type?
  end
end
