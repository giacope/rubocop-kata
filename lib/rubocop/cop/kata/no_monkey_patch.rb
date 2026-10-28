# frozen_string_literal: true

class RuboCop::Cop::Kata::NoMonkeyPatch < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Ownership

  MSG = "`%s` patches `%s` for every caller; use a refinement (`refine %s`) or a decorator object."
  MIXINS = %i[include prepend extend].freeze
  DEFINERS = %i[
    define_method define_singleton_method alias_method remove_method undef_method attr_reader attr_writer attr_accessor
  ].freeze
  EVALS = %i[class_eval class_exec module_eval module_exec instance_eval instance_exec].freeze
  SENDS = %i[send __send__ public_send].freeze
  CHANGES = %i[def defs alias].freeze
  CODE = /^\s*(?:def|alias|include|prepend|extend|define_method|alias_method|attr_\w+)\b/

  RESTRICT_ON_SEND = [*MIXINS, *DEFINERS, *EVALS, *SENDS].freeze

  def on_send(node)
    target = patched(node.receiver)
    verb = verb(node)
    return unless target && verb && changes?(node, verb)
    add_offense(node, message: format(MSG, label(node, verb), target, target))
  end

  def on_sclass(node)
    target = patched(node.identifier)
    return unless target && changing?(node.body)
    opening = node.loc.keyword.join(node.identifier.source_range)
    add_offense(opening, message: format(MSG, "class << #{target}", target, target))
  end

  private

  def patched(receiver)
    probe = receiver&.send_type? && receiver.method?(:singleton_class) ? receiver.receiver : receiver
    probe.const_name if stranger?(probe)
  end

  def stranger?(probe) = probe&.const_type? && !own?(probe) && !hooked?(probe)

  def hooked?(probe)
    names = hooks(probe.const_name)
    probe.each_ancestor(:any_block).any? { it.method?(:on_load) && names.include?(hook(it.send_node.first_argument)) }
  end

  def hook(name) = name&.sym_type? && name.value

  def hooks(name)
    spelled = name.gsub(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2').gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase.split("::")
    [spelled.join("_"), *(spelled[0..-2].join("_") if spelled.last == "base")].map(&:to_sym)
  end

  def label(node, verb)
    called = "#{node.receiver.source}.#{node.method_name}"
    SENDS.include?(node.method_name) ? "#{called}(:#{verb})" : called
  end

  def verb(node)
    return node.method_name unless SENDS.include?(node.method_name)
    name = node.first_argument
    name.value if name&.sym_type? && (MIXINS + DEFINERS).include?(name.value)
  end

  def changes?(node, verb)
    return true unless EVALS.include?(verb)
    body = node.block_node&.body
    return changing?(body) if body
    node.arguments.any? { it.type?(:str, :dstr) && CODE.match?(it.value) }
  end

  def changing?(body) = body&.each_node(*CHANGES, :send)&.any? { change?(it) }

  def change?(node) = CHANGES.include?(node.type) || (node.receiver.nil? && RESTRICT_ON_SEND.include?(node.method_name))
end
