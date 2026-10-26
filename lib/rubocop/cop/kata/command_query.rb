# frozen_string_literal: true

class RuboCop::Cop::Kata::CommandQuery < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Memoization
  include RuboCop::Cop::Kata::Roster
  include RuboCop::Cop::Kata::Answer

  MSG = "`%s` asks a question and changes state with `%s`; a query answers, a command acts."
  VALUE = "`%s` answers with a value and acts with `%s`; a query answers, a command acts. %s"
  ADVICE = "Split them, or return a new object instead of acting."
  OWNED = %i[ivar cvar gvar const self].freeze
  INPUTS = %i[arg optarg restarg kwarg kwoptarg kwrestarg blockarg].freeze
  CONSTRUCTORS = %i[initialize initialize_copy].freeze

  def on_def(node)
    return unless node.body
    inputs = node.arguments.each_node(*INPUTS).map(&:name)
    return judge(node, inputs, MSG) if node.predicate_method?
    judge(node, inputs, VALUE) if answers?(node)
  end

  alias on_defs on_def

  private

  def judge(method, inputs, message)
    changes = method.body.each_node(:ivasgn, :send, :csend).select { change?(it, inputs) }
    found = (changes + orders(method, inputs)).uniq(&:object_id)
    found.each { add_offense(it, message: format(message, method.method_name, label(it), ADVICE)) }
  end

  def orders(method, inputs) = discarded(method.body).select { order?(it, inputs) && !building?(it, method) }

  def change?(found, inputs) = found.ivasgn_type? ? !memoized?(found) : command?(found, inputs)

  def answers?(method)
    name = method.method_name
    !(CONSTRUCTORS.include?(name) || name.end_with?("!", "=")) && value?(tail(method.body))
  end

  def tail(body) = body.begin_type? ? body.children.fetch(-1) : body

  def discarded(body)
    return [] unless body.begin_type?
    body.children[0...-1].flat_map { statements(it) }
  end

  def statements(node)
    return node.branches.compact.flat_map { statements(it) } if node.if_type?
    return node.children.flat_map { statements(it) } if node.begin_type?
    node.call_type? ? [node] : []
  end

  def order?(call, inputs)
    return false if call.block_node || answer?(call) || raising?(call) || raises?(call)
    target = root(call)
    target.nil? || owned?(target, inputs)
  end

  def raises?(call) = listed?("RaisingMethods", call.method_name.to_s)

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

  def command?(call, inputs)
    name = call.method_name.to_s
    name.end_with?("!") && name != "!" && owned?(call.receiver, inputs) && !lookup?(call) && !raising?(call)
  end

  def raising?(call)
    holder = call.parent
    call.receiver&.const_type? && holder&.if_type? && holder.branches.compact.all? { it.equal?(call) }
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
