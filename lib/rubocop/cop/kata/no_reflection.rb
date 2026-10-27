# frozen_string_literal: true

class RuboCop::Cop::Kata::NoReflection < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::BootLayer

  FIELD = "`%s` reaches into another object's fields; ask it for what you need through a method it exposes."
  CALL = "`%s` calls `%s` past another object's interface; send it a message it answers in public."
  LOOKUP = "`%s` builds a constant's name at run time, hidden coupling; map the names to objects, or inject one."
  FIELDS = %i[instance_variable_get instance_variable_set instance_variables remove_instance_variable].freeze
  DISPATCH = %i[send __send__].freeze
  LOOKUPS = %i[const_get constantize safe_constantize].freeze
  SELF = %i[self].freeze

  RESTRICT_ON_SEND = [*FIELDS, *DISPATCH, *LOOKUPS].freeze

  def on_send(node)
    name = node.method_name
    return field(node) if FIELDS.include?(name)
    return call(node) if DISPATCH.include?(name)
    lookup(node)
  end

  alias on_csend on_send

  private

  def field(node)
    add_offense(node.loc.selector, message: format(FIELD, node.method_name)) if other?(node)
  end

  def call(node)
    target = node.first_argument
    return unless other?(node) && target&.type?(:sym, :str)
    add_offense(node.loc.selector, message: format(CALL, node.method_name, target.value))
  end

  def lookup(node)
    built = node.method?(:const_get) ? node.first_argument : node.receiver
    add_offense(node.loc.selector, message: format(LOOKUP, node.method_name)) if built&.dstr_type? && !seam?(node)
  end

  def other?(node) = !(node.receiver.nil? || SELF.include?(node.receiver.type))
end
