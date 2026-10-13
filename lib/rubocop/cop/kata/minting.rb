# frozen_string_literal: true

module RuboCop::Cop::Kata::Minting
  MINTERS = %i[attr attr_reader attr_writer attr_accessor define_method define_singleton_method alias_method].freeze
  SINGLE = %i[define_method define_singleton_method alias_method].freeze

  def on_send(node)
    return unless node.receiver.nil? || node.receiver.self_type?
    names = SINGLE.include?(node.method_name) ? node.arguments.first(1) : node.arguments
    names.select { it.type?(:sym, :str) }.each { mint(it.source_range, it.value.to_sym) }
  end

  def on_alias(node)
    name = node.new_identifier
    mint(name.source_range, name.value) if name.sym_type?
  end
end
