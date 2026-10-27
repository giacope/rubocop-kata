# frozen_string_literal: true

class RuboCop::Cop::Kata::NoSingleton < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster
  include RuboCop::Cop::Kata::BootLayer

  MIXIN = "`include Singleton` makes one global instance; build the object where it is needed and pass it in."
  CACHE = "`%s ||=` keeps one global instance on the class; build the object where it is needed and pass it in."
  CURRENT = "`%s` is a global with a class name, reset per request; pass what it holds to what needs it."
  THREAD = "`%s` is global state keyed by the thread; pass the value to what needs it."
  FIBER = "`%s` is global state keyed by the fiber; pass the value to what needs it."
  SETTING = "`%s` keeps one value on the class for every caller; pass it to the object that needs it."
  ACCESS = %i[[] []= fetch store key? delete thread_variable_get thread_variable_set thread_variable?].freeze
  SETTINGS = {
    cattr_accessor: SETTING, mattr_accessor: SETTING, cattr_writer: SETTING, mattr_writer: SETTING,
    thread_cattr_accessor: THREAD, thread_mattr_accessor: THREAD
  }.freeze

  def_node_matcher :singleton?, "(send nil? :include (const {nil? cbase} :Singleton))"
  KEEPS = %i[freeze tap].freeze

  def_node_matcher :maker?, "(send {nil? self const} :new ...)"

  def_node_matcher :current?, "(const (const {nil? cbase} :ActiveSupport) :CurrentAttributes)"

  def_node_matcher :ambient?, "(send (const {nil? cbase} {:Thread :RequestStore}) {:current :store})"

  def_node_matcher :keyed?, "(send (const {nil? cbase} {:Fiber :RequestStore}) {:[] :[]=} ...)"

  def_node_matcher :fiber?, "(send (const {nil? cbase} :Fiber) ...)"

  def on_send(node)
    return add_offense(node, message: MIXIN) if singleton?(node)
    return unless globals?
    return add_offense(node, message: setting(node)) if setting?(node)
    add_offense(node, message: state(node)) if shared?(node) && !seam?(node)
  end

  def on_class(node)
    return unless globals? && current?(node.parent_class)
    add_offense(node.parent_class, message: format(CURRENT, node.identifier.source))
  end

  def on_ivasgn(node)
    method = node.each_ancestor(:def, :defs).first
    return if method.nil?
    check(node) if method.defs_type? || method.each_ancestor(:sclass, :class, :module).first&.sclass_type?
  end

  def on_cvasgn(node) = check(node)

  private

  def globals? = cop_config["CheckGlobals"]

  def setting(node)
    named = "#{node.method_name} #{node.first_argument&.source}#{", …" if node.arguments.size > 1}"
    format(SETTINGS.fetch(node.method_name), named)
  end

  def state(node)
    slot = node.method?(:[]) || node.method?(:[]=) ? "[#{node.first_argument&.source}]" : ".#{node.method_name}"
    format(fiber?(node) ? FIBER : THREAD, node.receiver.source + slot)
  end

  def setting?(node) = node.receiver.nil? && SETTINGS.key?(node.method_name) && !seam?(node)

  def shared?(node) = keyed?(node) || (ambient?(node.receiver) && ACCESS.include?(node.method_name))

  def check(node)
    holder = node.parent
    return unless holder&.or_asgn_type?
    return unless node.each_ancestor(:def, :defs).first&.method?(:instance) || instance?(holder.children[1])
    add_offense(holder, message: format(CACHE, node.children.first))
  end

  def instance?(value) = held(value).any? { maker?(it) && !value?(it.receiver) }

  def held(value)
    passed = value ? through(value) : []
    passed.one? && passed.first.equal?(value) ? passed : passed.flat_map { held(it) }
  end

  def through(value)
    return value.branches if value.type?(:if, :case)
    return value.children if value.type?(:and, :or)
    return [value.children.last] if value.type?(:begin, :kwbegin)
    return [value.send_node] if value.any_block_type?
    [value.send_type? && KEEPS.include?(value.method_name) ? value.receiver : value]
  end

  def value?(maker) = maker&.const_type? && listed?("AllowedConstructors", maker.const_name)
end
