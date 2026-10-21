# frozen_string_literal: true

require "prism"

class RuboCop::Kata::Kinship
  def initialize(tree)
    @tree = tree
  end

  def records
    facts(@tree, []).each_with_object({}) do |(scope, kind, *rest), found|
      held = found[scope] ||= { parents: [], methods: {} }
      kind == :parent ? held[:parents] << rest : (held[:methods][rest.first] ||= []).concat(rest.drop(1))
    end
  end

  private

  def facts(node, scope, method = nil)
    case node
    when *RuboCop::Kata::Lineage::NESTS then nest(node, scope)
    when Prism::DefNode then node.receiver || scope.empty? ? [] : defined(node, scope)
    when Prism::CallNode then [*call(node, scope, method), *inner(node, scope, method)]
    else inner(node, scope, method)
    end
  end

  def inner(node, scope, method) = node.compact_child_nodes.flat_map { facts(it, scope, method) }

  def nest(node, scope)
    path = node.constant_path.slice
    name = path.start_with?("::") || scope.empty? ? path.delete_prefix("::") : "#{scope.last}::#{path}"
    parent = node.superclass if node.is_a?(Prism::ClassNode)
    [[name, :method, nil], *([[name, :parent, parent.slice, scope]] if parent), *inner(node, [*scope, name], nil)]
  end

  def defined(node, scope)
    method = node.name.to_s
    [[scope.last, :method, method], *inner(node, scope, method)]
  end

  def call(node, scope, method)
    return [] if scope.empty?
    mixin = method.nil? && node.receiver.nil? && RuboCop::Kata::Lineage::MIXINS.include?(node.name)
    return mixins(node, scope) if mixin
    return [] unless method && RuboCop::Kata::Lineage::CALLERS.any? { node.receiver.is_a?(it) }
    [[scope.last, :method, method, node.name.to_s]]
  end

  def mixins(node, scope)
    modules = Array(node.arguments&.arguments).select { it.respond_to?(:full_name) }
    modules.map { [scope.last, :parent, it.slice, scope[0..-2]] }
  end
end
