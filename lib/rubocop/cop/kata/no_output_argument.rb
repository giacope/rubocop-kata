# frozen_string_literal: true

class RuboCop::Cop::Kata::NoOutputArgument < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster
  include RuboCop::Kata::Order
  include RuboCop::Cop::Kata::Tally

  MSG = "%s changes the caller's `%s`; return a new value, or move the change to the object that owns it."
  MANY_MSG = "This method changes the caller's %s; return a new value, or move the change to the object that owns it."
  INPUTS = %i[arg optarg kwarg kwoptarg].freeze
  CHARSET = /\A(?:\^?(?:[^[:alnum:]]|[[:alnum:]]-[[:alnum:]])+)\z/
  SCOPES = %i[def defs sclass].freeze
  WRITES = %i[op_asgn or_asgn and_asgn].freeze
  SHADOWS = %i[arg optarg restarg kwarg kwoptarg kwrestarg blockarg shadowarg].freeze

  def on_def(node)
    names = node.arguments.select { INPUTS.include?(it.type) }.map(&:name)
    names -= list("AllowedNames").map(&:to_sym)
    changes = node.body ? node.body.each_node(:send, :csend).select { changed?(it, names, node) } : []
    report(changes) unless changes.empty?
  end

  alias on_defs on_def

  private

  def report(changes)
    held = changes.group_by { it.receiver.children.first }.transform_values { |calls| calls.map { label(it) } }
    add_offense(changes.first, message: message(held))
  end

  def message(held)
    return format(MSG, tally(held.values.first), held.keys.first) if held.size == 1
    format(MANY_MSG, joined(held.map { |name, labels| "`#{name}` (#{tally(labels)})" }))
  end

  def changed?(call, names, method)
    target = call.receiver
    return false unless target&.lvar_type? && names.include?(target.children.first) && mutation?(call)
    !outside?(call, method) && !fresh?(target, method)
  end

  def label(call) = written?(call) ? :[]= : call.method_name

  def mutation?(call)
    name = call.method_name
    return false if name == :delete && call.arguments? && call.arguments.all? { charset?(it) }
    listed?("MutatingMethods", name.to_s) || (name == :[] && written?(call))
  end

  def charset?(argument) = argument.str_type? && CHARSET.match?(argument.value)

  def written?(call)
    holder = call.parent
    WRITES.include?(holder&.type) && holder.children.first.equal?(call)
  end

  def outside?(call, method)
    call.each_ancestor.take_while { !it.equal?(method) }.any? { scope?(it, call.receiver.children.first) }
  end

  def scope?(node, name)
    SCOPES.include?(node.type) || (node.block_type? && node.children[1].each_node(*SHADOWS).any? { it.name == name })
  end

  def fresh?(target, method)
    name = target.children.first
    method.each_descendant(:lvasgn).any? { it.children.first == name && precedes?(it, target) }
  end
end
