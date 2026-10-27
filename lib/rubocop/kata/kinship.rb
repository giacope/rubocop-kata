# frozen_string_literal: true

require "prism"

class RuboCop::Kata::Kinship
  HOOK = /\A:(\w+)\z/

  def self.parse(source) = new(Prism.parse(source).value)

  def initialize(tree)
    @tree = tree
  end

  def hooks = hooked(@tree, nil)

  def records
    facts(@tree, []).each_with_object({}) do |(scope, kind, *rest), found|
      held = found[scope] ||= { parents: [], methods: {} }
      next held[:superclass] = rest if kind == :superclass
      kind == :parent ? held[:parents] << rest : (held[:methods][rest.first] ||= []).concat(rest.drop(1))
    end
  end

  private

  def facts(node, scope, method = nil)
    case node
    when *RuboCop::Kata::Lineage::NESTS then nest(node, scope)
    when Prism::DefNode then defined(node, scope)
    when Prism::CallNode then [*call(node, scope, method), *inner(node, scope, method)]
    else inner(node, scope, method)
    end
  end

  def inner(node, scope, method) = node.compact_child_nodes.flat_map { facts(it, scope, method) }

  def nest(node, scope)
    path = node.constant_path.slice
    name = path.start_with?("::") || scope.empty? ? path.delete_prefix("::") : "#{scope.last}::#{path}"
    parent = node.superclass if node.is_a?(Prism::ClassNode)
    lineage = written(parent, node).map { [name, :parent, it, scope] }
    lineage << [name, :superclass, parent.slice, scope] if parent
    [[name, :method, nil], *lineage, *inner(node, [*scope, name], nil)]
  end

  def defined(node, scope)
    return [] unless own?(node)
    return [[scope.last, :method, "self.#{node.name}"]] if node.receiver
    method = node.name.to_s
    [[scope.last, :method, method], *inner(node, scope, method)]
  end

  def call(node, scope, method)
    return [] unless own?(node)
    [[scope.last, :method, method, node.name.to_s]]
  end

  def own?(node) = RuboCop::Kata::Lineage::CALLERS.any? { node.receiver.is_a?(it) }

  def written(parent, node) = [*parent&.slice, *Array(node.body&.body).flat_map { mixed(it) }]

  def hooked(node, hook)
    nested = node.compact_child_nodes
    return nested.flat_map { hooked(it, hook) } unless node.is_a?(Prism::CallNode)
    hook = loaded(node) || hook
    [*mixins(node, hook), *nested.flat_map { hooked(it, hook) }]
  end

  def loaded(call)
    name = call.arguments&.arguments&.first if call.name == :on_load && call.block
    name&.slice&.[](HOOK, 1)
  end

  def mixins(call, hook)
    return [] unless hook && call.receiver.nil?
    mixed(call).map { [it.delete_prefix("::"), hook] }
  end

  def mixed(statement)
    return [] unless statement.is_a?(Prism::CallNode) && RuboCop::Kata::Lineage::MIXINS.include?(statement.name)
    Array(statement.arguments&.arguments).map(&:slice)
  end
end
