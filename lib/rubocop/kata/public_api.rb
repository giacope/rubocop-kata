# frozen_string_literal: true

class RuboCop::Kata::PublicApi
  DEFINITIONS = %i[class module def defs send block casgn].freeze
  METHODS = %i[def defs send block].freeze
  ACCESSORS = %i[attr attr_reader attr_writer attr_accessor].freeze
  HIDDEN = %i[private protected private_class_method].freeze
  OPEN = %i[public module_function].freeze

  def initialize(ast)
    @ast = ast
  end

  def lines = @ast ? @ast.each_node(*DEFINITIONS).select { entry?(it) && published?(it) }.to_set(&:first_line) : Set.new

  private

  def entry?(node)
    case node.type
    when :send then node.receiver.nil? && ACCESSORS.include?(node.method_name)
    when :block then node.send_node.receiver.nil? && node.send_node.method?(:define_method)
    when :casgn then !hidden_constant?(node)
    else true
    end
  end

  def hidden_constant?(node)
    holder = node.parent
    return false unless holder&.begin_type?
    holder.each_child_node(:send).any? do |call|
      call.method?(:private_constant) && call.arguments.any? { it.sym_type? && it.value == node.name }
    end
  end

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

  def scope?(node) = node.send_type? && node.bare_access_modifier?
end
