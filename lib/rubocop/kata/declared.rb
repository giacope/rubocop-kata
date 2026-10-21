# frozen_string_literal: true

class RuboCop::Kata::Declared
  FACTORIES = %w[Class.new Module.new Struct.new Data.define].freeze

  def initialize(ast)
    @ast = ast
  end

  def types = @ast.each_node(:class, :module, :casgn).filter_map { named(it) }.flat_map { it.split("::") }

  private

  def named(node)
    return node.identifier.const_name unless node.casgn_type?
    scope = node.namespace
    [(scope.const_name if scope&.const_type?), node.name.to_s].compact.join("::") if built?(node.expression)
  end

  def built?(value)
    call = value&.block_type? ? value.send_node : value
    return false unless call&.send_type? && call.receiver&.const_type?
    FACTORIES.include?("#{call.receiver.const_name}.#{call.method_name}")
  end
end
