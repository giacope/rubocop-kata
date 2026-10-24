# frozen_string_literal: true

require "prism"

class RuboCop::Kata::Messages
  include RuboCop::Kata::Scoped

  NESTS = [Prism::ClassNode, Prism::ModuleNode].freeze
  SWITCHES = { public: :public, private: :private, protected: :protected, module_function: :public }.freeze
  NAMES = [Prism::SymbolNode, Prism::StringNode].freeze

  def initialize(source)
    @source = source
  end

  def records = walk(Prism.parse(@source).value, nil, :private)

  private

  def walk(node, scope, shown)
    case node
    when Prism::StatementsNode then sequence(node.body, scope, shown)
    when *NESTS then nested(node.body, qualified(node.constant_path.slice, scope))
    when Prism::SingletonClassNode then nested(node.body, scope)
    when Prism::DefNode then [defined(node, scope, shown)]
    when Prism::CallNode then called(node, scope, shown)
    else node.compact_child_nodes.flat_map { walk(it, scope, shown) }
    end
  end

  def defined(node, scope, shown) = [scope, node.name.to_s, node.receiver ? :public : shown]

  def called(call, scope, shown)
    refined = Array(call.arguments&.arguments).first&.slice if call.name == :refine && call.receiver.nil?
    call.compact_child_nodes.flat_map { walk(it, refined || scope, shown) }
  end

  def nested(body, scope) = body ? walk(body, scope, :public) : []

  def sequence(statements, scope, shown)
    found = []
    statements.each do |statement|
      switch = switch(statement)
      arguments = Array(statement.arguments&.arguments) if switch
      shown = switch if switch && arguments.empty?
      found.concat(switch ? arguments.flat_map { marking(it, scope, switch) } : walk(statement, scope, shown))
    end
    marked(found, scope)
  end

  def marking(argument, scope, switch)
    NAMES.any? { argument.is_a?(it) } ? [[:marked, argument.unescaped, switch]] : walk(argument, scope, switch)
  end

  def marked(found, scope)
    marks, records = found.partition { it.first == :marked }
    switched = marks.to_h { it.drop(1) }
    records.map { |owner, name, shown| [owner, name, owner == scope ? switched.fetch(name, shown) : shown] }
  end

  def switch(statement)
    SWITCHES[statement.name] if statement.is_a?(Prism::CallNode) && statement.receiver.nil?
  end
end
