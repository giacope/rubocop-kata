# frozen_string_literal: true

class RuboCop::Kata::PublicApi
  DEFINITIONS = %i[class module def defs].freeze
  METHODS = %i[def defs].freeze
  HIDDEN = %i[private protected private_class_method].freeze
  SCOPES = %i[private protected public module_function].freeze
  OPEN = %i[public module_function].freeze

  def initialize(ast)
    @ast = ast
  end

  def lines = @ast ? @ast.each_node(*DEFINITIONS).select { published?(it) }.to_set(&:first_line) : Set.new

  private

  def published?(node)
    return true unless METHODS.include?(node.type)
    holder = node.parent
    return !HIDDEN.include?(holder.method_name) if holder&.send_type?
    owner = holder&.begin_type? ? holder.parent : holder
    !owner.nil? && (node.defs_type? || visible?(node, holder))
  end

  def visible?(node, holder)
    return true unless holder.begin_type?
    marker = holder.children.take_while { !it.equal?(node) }.reverse.find { scope?(it) }
    marker.nil? || OPEN.include?(marker.method_name)
  end

  def scope?(node) = node.send_type? && node.receiver.nil? && !node.arguments? && SCOPES.include?(node.method_name)
end
