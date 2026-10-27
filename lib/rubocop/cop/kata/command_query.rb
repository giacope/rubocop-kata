# frozen_string_literal: true

class RuboCop::Cop::Kata::CommandQuery < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Memoization
  include RuboCop::Cop::Kata::Roster
  include RuboCop::Cop::Kata::Answer
  include RuboCop::Cop::Kata::Lending

  MSG = "`%s` asks a question and changes state with `%s`; a query answers, a command acts."
  VALUE = "`%s` answers with a value and acts with `%s`; a query answers, a command acts. %s"
  ADVICE = "Split them, or return a new object instead of acting."
  OWNED = %i[ivar cvar gvar const self].freeze
  CONSTRUCTORS = %i[initialize initialize_copy].freeze
  BRANCHES = %i[if case when and or].freeze
  ANSWERS = %i[def defs return].freeze

  def on_def(node)
    body = node.body
    return unless body
    return judge(node, body, MSG) if node.predicate_method?
    judge(node, body, VALUE) if every? && answers?(node, body)
  end

  alias on_defs on_def

  private

  def judge(method, body, message)
    changes = body.each_node(:ivasgn, :send, :csend).select { change?(it, method) }
    orders = discarded(body).select { order?(it, method) && !building?(it, method) }
    name = method.method_name
    (changes + orders).uniq(&:object_id).each { add_offense(it, message: format(message, name, label(it), ADVICE)) }
  end

  def change?(found, method) = found.ivasgn_type? ? !memoized?(found) : command?(found, method)

  def answers?(method, body)
    name = method.method_name
    !(CONSTRUCTORS.include?(name) || name.end_with?("!", "=")) && value?(tail(body))
  end

  def every? = cop_config["CheckEveryQuery"]

  def discarded(body)
    return [] unless every? && body.begin_type?
    body.children[0...-1].flat_map { statements(it) }
  end

  def statements(node)
    return node.branches.compact.flat_map { statements(it) } if node.if_type?
    return node.children.flat_map { statements(it) } if node.begin_type?
    node.call_type? ? [node] : []
  end

  def order?(call, method)
    return false if call.block_node || answer?(call) || raising?(call)
    !listed?("RaisingMethods", call.method_name.to_s) && owned?(root(call), method)
  end

  def building?(call, method)
    locals = method.each_node(:lvasgn).map { it.children.first }
    (call.receiver.nil? || call.receiver.const_type?) &&
      call.arguments.any? { it.lvar_type? && locals.include?(it.children.first) }
  end

  def root(call)
    target = call.receiver
    target = target.receiver while target&.call_type? && target.receiver
    target
  end

  def command?(call, method)
    name = call.method_name.to_s
    name.end_with?("!") && name != "!" && owned?(call.receiver, method) && !used?(call) && !raising?(call)
  end

  def raising?(call)
    holder = call.parent
    call.receiver&.const_type? && holder&.if_type? && holder.branches.compact.all? { it.equal?(call) }
  end

  def used?(node)
    holder = node.parent
    return holder.children.last.equal?(node) && used?(holder) if holder.type?(:begin, :kwbegin)
    return used?(holder) if holder.any_block_type?
    return used?(holder) if holder.type?(*BRANCHES) && !holder.children.first.equal?(node)
    !holder.type?(*ANSWERS)
  end

  def owned?(target, method)
    target.nil? || OWNED.include?(target.type) || borrowed?(target, method) ||
      (target.send_type? && target.receiver.nil? && !target.arguments?)
  end

  def label(found) = found.ivasgn_type? ? "#{found.children.first} =" : found.method_name
end
