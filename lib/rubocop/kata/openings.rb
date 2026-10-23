# frozen_string_literal: true

require "prism"

class RuboCop::Kata::Openings
  include RuboCop::Kata::Scoped

  NESTS = [Prism::ClassNode, Prism::ModuleNode].freeze

  def initialize(path, source)
    @path = path
    @source = source
  end

  def records = walk(Prism.parse(@source).value, nil)

  private

  def walk(node, scope)
    return node.compact_child_nodes.flat_map { walk(it, scope) } unless NESTS.any? { node.is_a?(it) }
    name = qualified(node.constant_path.slice, scope)
    statements = statements(node.body)
    [[name, @path, node.location.start_line, statements.size], *statements.flat_map { walk(it, name) }]
  end

  def statements(body)
    return [] if body.nil?
    body.is_a?(Prism::StatementsNode) ? body.body : [body]
  end
end
