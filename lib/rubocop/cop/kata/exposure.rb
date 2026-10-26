# frozen_string_literal: true

module RuboCop::Cop::Kata::Exposure
  include RuboCop::Cop::VisibilityHelp

  HIDDEN = %i[private protected].freeze

  private

  def hidden?(node)
    holder = node.parent
    return true if holder&.send_type? && HIDDEN.include?(holder.method_name) && holder.receiver.nil?
    HIDDEN.include?(node_visibility(node)) || named_hidden?(node)
  end

  def named_hidden?(node)
    names = node.def_type? ? [node.method_name] : node.arguments.select(&:sym_type?).map(&:value)
    node.each_ancestor(:class, :module).first(1).flat_map { hiders(it) }.intersect?(names)
  end

  def hiders(scope)
    hiding = statements(scope).select { it.send_type? && HIDDEN.include?(it.method_name) }
    hiding.flat_map { |call| call.arguments.select(&:sym_type?).map(&:value) }
  end

  def statements(scope)
    body = scope.body
    body&.begin_type? ? body.children : [body].compact
  end
end
