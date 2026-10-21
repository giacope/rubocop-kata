# frozen_string_literal: true

class RuboCop::Cop::Kata::NoOutputArgument < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster

  MSG = "`%s` changes the caller's `%s`; return a new value, or move the change to the object that owns it."
  INPUTS = %i[arg optarg kwarg kwoptarg].freeze
  SCOPES = %i[def defs sclass].freeze
  WRITES = %i[op_asgn or_asgn and_asgn].freeze
  SHADOWS = %i[arg optarg restarg kwarg kwoptarg kwrestarg blockarg shadowarg].freeze

  def on_def(node)
    names = node.arguments.select { INPUTS.include?(it.type) }.map(&:name)
    names -= list("AllowedNames").map(&:to_sym)
    node.body&.each_node(:send, :csend) { judge(it, names, node) }
  end

  alias on_defs on_def

  private

  def judge(call, names, method)
    target = call.receiver
    return unless target&.lvar_type?
    name = target.children.first
    return unless names.include?(name) && mutation?(call)
    return if outside?(call, method) || fresh?(target, method)
    add_offense(call, message: format(MSG, label(call), name))
  end

  def label(call) = written?(call) ? :[]= : call.method_name

  def mutation?(call)
    name = call.method_name
    listed?("MutatingMethods", name.to_s) || (name == :[] && written?(call))
  end

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
    start = target.source_range.begin_pos
    method.each_descendant(:lvasgn).any? { it.children.first == name && it.source_range.end_pos <= start }
  end
end
