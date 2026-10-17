# frozen_string_literal: true

class RuboCop::Cop::Kata::CommandQuery < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Memoization

  MSG = "`%s` asks a question and changes state with `%s`; a query answers, a command acts."
  OWNED = %i[ivar cvar gvar const self].freeze
  INPUTS = %i[arg optarg restarg kwarg kwoptarg kwrestarg blockarg].freeze

  def on_def(node)
    return unless node.predicate_method?
    inputs = node.arguments.each_node(*INPUTS).map(&:name)
    node.body&.each_node(:ivasgn, :send, :csend) { judge(it, node, inputs) }
  end

  alias on_defs on_def

  private

  def judge(found, method, inputs)
    return unless found.ivasgn_type? ? !memoized?(found) : command?(found, inputs)
    add_offense(found, message: format(MSG, method.method_name, label(found)))
  end

  def command?(call, inputs)
    name = call.method_name.to_s
    name.end_with?("!") && name != "!" && owned?(call.receiver, inputs) && !lookup?(call)
  end

  def lookup?(call)
    holder = call.parent
    !holder.nil? && (holder.assignment? || (holder.call_type? && holder.receiver.equal?(call)))
  end

  def owned?(target, inputs)
    target.nil? || OWNED.include?(target.type) || (target.lvar_type? && inputs.include?(target.children.first)) ||
      (target.send_type? && target.receiver.nil? && !target.arguments?)
  end

  def label(found) = found.ivasgn_type? ? "#{found.children.first} =" : found.method_name
end
