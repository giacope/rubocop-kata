# frozen_string_literal: true

require "prism"

class RuboCop::Kata::Definitions
  FACTORIES = %w[Class.new Module.new Struct.new Data.define].freeze
  NESTS = [Prism::ClassNode, Prism::ModuleNode].freeze

  def initialize(source)
    @source = source
  end

  def names = walk(Prism.parse(@source).value, nil).to_set

  private

  def walk(node, scope)
    case node
    when *NESTS then nest(node, scope)
    when Prism::ConstantWriteNode, Prism::ConstantPathWriteNode then [*built(node, scope), *walk(node.value, scope)]
    else node.compact_child_nodes.flat_map { walk(it, scope) }
    end
  end

  def nest(node, scope)
    name = qualified(node.constant_path.slice, scope)
    [*(name unless wrapper?(node)), *Array(node.body&.body).flat_map { walk(it, name) }]
  end

  def built(node, scope)
    path = node.respond_to?(:target) ? node.target.slice : node.name.to_s
    factory?(node.value) ? [qualified(path, scope)] : []
  end

  def qualified(path, scope)
    return path.delete_prefix("::") if path.start_with?("::") || scope.nil?
    "#{scope}::#{path}"
  end

  def wrapper?(node)
    body = node.body&.body
    return false if body.nil? || body.empty? || (node.is_a?(Prism::ClassNode) && node.superclass)
    body.all? { |statement| NESTS.any? { statement.is_a?(it) } }
  end

  def factory?(value)
    receiver = value.receiver if value.is_a?(Prism::CallNode)
    return false unless receiver.is_a?(Prism::ConstantReadNode) || receiver.is_a?(Prism::ConstantPathNode)
    FACTORIES.include?("#{receiver.slice.delete_prefix("::")}.#{value.name}")
  end
end
