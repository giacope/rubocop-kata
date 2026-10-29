# frozen_string_literal: true

class RuboCop::Cop::Kata::NoReflection < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::BootLayer

  FIELD = "`%s` reaches into another object's fields; ask it for what you need through a method it exposes."
  CALL = "`%s` calls `%s` past another object's interface; send it a message it answers in public."
  COMPUTED = "`%s` sends a computed name to another object, private methods included; " \
    "`public_send` keeps the dispatch to its interface."
  MODULE = "`%s` sends a computed name to a class or module, whose private methods (`private`, " \
    "`module_function`, `remove_const`) `public_send` cannot reach; let the class say it in its own body, " \
    "or decorate its objects instead of changing the class from outside."
  PRIVATE = "`%s` sends a computed name to another object to reach its private methods, which `public_send` " \
    "cannot; send it a message it answers in public, or map the names to objects."
  LOOKUP = "`%s` builds a constant's name at run time, hidden coupling; map the names to objects, or inject one."
  FIELDS = %i[instance_variable_get instance_variable_set instance_variables remove_instance_variable].freeze
  DISPATCH = %i[send __send__].freeze
  LOOKUPS = %i[const_get constantize safe_constantize].freeze
  SELF = %i[self].freeze
  MODULES = %i[
    module_eval class_eval module_exec class_exec instance_method public_instance_method instance_methods
    private_instance_methods method_defined? public_method_defined? private_method_defined?
    protected_method_defined? define_method alias_method remove_method undef_method attr_accessor attr_reader
    attr_writer const_get const_set const_defined? ancestors included_modules superclass
  ].freeze

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
    return unless other?(node) && target && !forward?(node)
    name = node.method_name
    message = target.type?(:sym, :str) ? format(CALL, name, target.value) : format(computed(node), name)
    add_offense(node.loc.selector, message: message)
  end

  def forward?(node) = DISPATCH.include?(node.each_ancestor(:def).first&.method_name)

  def computed(node)
    receiver = node.receiver
    return MODULE if module?(receiver, node)
    asked(receiver, node).any? { it.method?(:respond_to?) && it.last_argument&.true_type? } ? PRIVATE : COMPUTED
  end

  def module?(receiver, node) = asked(receiver, node).any? { MODULES.include?(it.method_name) }

  def asked(receiver, node)
    names = labels(receiver)
    scope = node.each_ancestor(:class, :module).first || processed_source.ast
    scope.each_node(:send, :csend).select { labels(it.receiver).intersect?(names) }
  end

  def labels(receiver)
    return [receiver.children.first.to_s.delete_prefix("@")] if receiver&.type?(:ivar, :lvar)
    receiver&.send_type? && receiver.receiver.nil? && !receiver.arguments? ? [receiver.method_name.to_s] : []
  end

  def lookup(node)
    built = node.method?(:const_get) ? node.first_argument : node.receiver
    add_offense(node.loc.selector, message: format(LOOKUP, node.method_name)) if built&.dstr_type? && !seam?(node)
  end

  def other?(node) = !(node.receiver.nil? || SELF.include?(node.receiver.type))
end
