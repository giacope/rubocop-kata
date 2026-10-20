# frozen_string_literal: true

class RuboCop::Cop::Kata::NoSetter < RuboCop::Cop::Base
  MACRO = "`%s` mints a setter; take the value in the constructor and return a new object to change it."
  WRITER = "`%s` is a setter; take the value in the constructor and return a new object to change it."
  PROTOCOLS = %i[[]=].freeze

  RESTRICT_ON_SEND = %i[attr_writer attr_accessor define_method].freeze

  def_node_matcher :minted, "(send {nil? self} :define_method ${sym str dsym} ...)"

  def on_send(node)
    return writer(node) if node.method?(:define_method)
    add_offense(node.loc.selector, message: format(MACRO, node.method_name)) unless node.receiver
  end

  def on_def(node)
    name = node.method_name
    return unless node.assignment_method? && !PROTOCOLS.include?(name)
    add_offense(node.loc.name, message: format(WRITER, name))
  end

  alias on_defs on_def

  private

  def writer(node)
    minted(node) do |name|
      text = name.dsym_type? ? name.children.last&.source.to_s : name.value.to_s
      add_offense(name, message: format(WRITER, name.source)) if text.end_with?("=") && !PROTOCOLS.include?(text.to_sym)
    end
  end
end
