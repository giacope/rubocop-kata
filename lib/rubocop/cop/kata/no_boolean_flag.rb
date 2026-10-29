# frozen_string_literal: true

class RuboCop::Cop::Kata::NoBooleanFlag < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster

  MSG = "A boolean flag is two methods trapped in one; call the method the flag chooses, split in two."
  DEFAULT_MSG = "`%s` defaults to a boolean flag, two methods trapped in one; split them, one method per value."
  PLACEHOLDER = /\?|(?<!:):\w/
  DISPATCH = %i[send public_send __send__].freeze
  STORES = %i[ivasgn cvasgn gvasgn pair].freeze

  def_node_matcher :expected?, "(send (send nil? :receive ...) :with ...)"

  def on_send(node)
    return if node.operator_method? || node.assignment_method? || allowed?(node.method_name) || expected?(node)
    node.arguments.each_with_index do |argument, index|
      add_offense(argument, message: MSG) if flag?(node, argument, index)
    end
  end

  def on_def(node)
    return if allowed?(node.method_name)
    node.arguments.each { flag(it) }
  end

  alias on_defs on_def

  private

  def flag?(node, argument, index)
    return false unless argument.boolean_type?
    before = node.arguments.first(index)
    before.none? { bound?(it) } && !(before.first&.sym_type? && !DISPATCH.include?(node.method_name)) &&
      !stored?(node, index)
  end

  def stored?(node, index)
    return false unless node.receiver.nil? || node.receiver.self_type?
    callees = processed_source.ast.each_node(:def).select { it.method?(node.method_name) }
    !callees.empty? && callees.all? { kept?(it, index) }
  end

  def kept?(callee, index)
    names = positional(callee, index).map(&:name)
    uses = callee.each_node(:lvar).select { names.include?(it.children.first) }
    uses.any? { store?(it) } && uses.none? { tested?(it) }
  end

  def positional(callee, index)
    parameters = callee.arguments.first(index + 1)
    parameters.size > index && parameters.all? { it.type?(:arg, :optarg) } ? parameters.last(1) : []
  end

  def tested?(use) = use.parent.conditional? || use.parent.operator_keyword?

  def store?(use)
    holder = use.parent
    return true if holder.type?(*STORES)
    holder.send_type? && (holder.setter_method? || holder.method?(:[]=)) && holder.last_argument.equal?(use)
  end

  def bound?(argument) = argument.type?(:str, :dstr) && PLACEHOLDER.match?(argument.source)

  def flag(argument)
    return unless argument.optarg_type? && argument.default_value.boolean_type?
    add_offense(argument, message: format(DEFAULT_MSG, argument.name))
  end

  def allowed?(name) = listed?("AllowedMethods", name.to_s)
end
