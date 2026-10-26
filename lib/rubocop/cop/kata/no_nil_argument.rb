# frozen_string_literal: true

class RuboCop::Cop::Kata::NoNilArgument < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster

  MSG = "`%s` defaults to nil, then is asked if it came: two methods in one. Split them, or default to a null object."
  KEPT = "`%s` defaults to nil, and `%s` is asked if it came: two objects in one. Default to a null object."
  DEFAULTS = %i[optarg kwoptarg].freeze
  PROBES = %i[nil? present? blank? ! try].freeze
  EQUALITIES = %i[== != equal?].freeze
  LOGIC = %i[or and].freeze
  BRANCHES = %i[if while until].freeze
  SCOPES = { lvar: %i[def defs class module sclass], ivar: %i[defs class module sclass] }.freeze

  def_node_matcher :copied, "(ivasgn $_ (lvar %1))"

  def on_def(node)
    return if listed?("AllowedMethods", node.method_name.to_s)
    node.arguments.each { judge(it, node) if DEFAULTS.include?(it.type) && it.default_value.nil_type? }
  end

  alias on_defs on_def

  private

  def judge(argument, method)
    name = argument.name
    return add_offense(argument, message: format(MSG, name)) if asked?(method.body, :lvar, name)
    homes = method.each_ancestor(:class).take(1)
    fields = homes.flat_map { |home| kept(method, name).select { asked?(home, :ivar, it) } }
    add_offense(argument, message: format(KEPT, name, fields.first)) unless fields.empty?
  end

  def kept(method, name)
    return [] unless method.method?(:initialize) && method.body
    method.body.each_node(:ivasgn).filter_map { copied(it, name) }
  end

  def asked?(body, type, name)
    return false unless body
    body.each_node(type, :lvasgn).any? { it.children.first == name && local?(it, body, type) && question?(it) }
  end

  def local?(found, body, type)
    found.each_ancestor.take_while { !it.equal?(body) }.none? { SCOPES.fetch(type).include?(it.type) }
  end

  def question?(found)
    holder = found.parent
    return false unless holder
    return holder.or_asgn_type? if found.lvasgn_type?
    probed?(found, holder) || tested?(found, holder)
  end

  def probed?(found, holder)
    return holder.receiver.equal?(found) if holder.csend_type?
    return false unless holder.send_type?
    name = holder.method_name
    return holder.receiver.equal?(found) if PROBES.include?(name)
    EQUALITIES.include?(name) && [holder.receiver, *holder.arguments].any?(&:nil_type?)
  end

  def tested?(found, holder)
    return holder.condition.equal?(found) if BRANCHES.include?(holder.type)
    return holder.lhs.equal?(found) || condition?(holder) if LOGIC.include?(holder.type)
    holder.case_type? && holder.condition.equal?(found) && holder.when_branches.any? { nil_branch?(it) }
  end

  def condition?(logic)
    holder = logic.parent
    BRANCHES.include?(holder&.type) && holder.condition.equal?(logic)
  end

  def nil_branch?(branch) = branch.conditions.any?(&:nil_type?)
end
