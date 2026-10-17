# frozen_string_literal: true

class RuboCop::Cop::Kata::NoSetter < RuboCop::Cop::Base
  MACRO = "`%s` mints a setter; take the value in the constructor and return a new object to change it."
  WRITER = "`%s` is a setter; take the value in the constructor and return a new object to change it."
  PROTOCOLS = %i[[]=].freeze

  RESTRICT_ON_SEND = %i[attr_writer attr_accessor].freeze

  def on_send(node)
    add_offense(node.loc.selector, message: format(MACRO, node.method_name)) unless node.receiver
  end

  def on_def(node)
    name = node.method_name
    return unless node.assignment_method? && !PROTOCOLS.include?(name)
    add_offense(node.loc.name, message: format(WRITER, name))
  end

  alias on_defs on_def
end
