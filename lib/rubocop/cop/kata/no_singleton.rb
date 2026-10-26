# frozen_string_literal: true

class RuboCop::Cop::Kata::NoSingleton < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster
  include RuboCop::Cop::Kata::BootLayer

  MIXIN = "`include Singleton` makes one global instance; build the object where it is needed and pass it in."
  CACHE = "`%s ||=` keeps one global instance on the class; build the object where it is needed and pass it in."
  CURRENT = "`%s` is a global with a class name, reset per request; pass what it holds to what needs it."
  THREAD = "`%s` is global state keyed by the thread; pass the value to what needs it."
  SETTING = "`%s` keeps one value on the class for every caller; pass it to the object that needs it."
  ACCESS = %i[[] []= fetch store key? delete thread_variable_get thread_variable_set thread_variable?].freeze
  SETTINGS = %i[
    cattr_accessor mattr_accessor cattr_writer mattr_writer thread_cattr_accessor thread_mattr_accessor
  ].freeze

  def_node_matcher :singleton?, "(send nil? :include (const {nil? cbase} :Singleton))"
  KEEPS = %i[freeze tap].freeze

  def_node_matcher :maker?, "(send {nil? self const} :new ...)"

  def_node_matcher :current?, "(const (const {nil? cbase} :ActiveSupport) :CurrentAttributes)"

  def_node_matcher :ambient?, "(send (const {nil? cbase} {:Thread :RequestStore}) {:current :store})"

  def_node_matcher :keyed?, "(send (const {nil? cbase} {:Fiber :RequestStore}) {:[] :[]=} ...)"

  def on_send(node)
    return add_offense(node, message: MIXIN) if singleton?(node)
    return add_offense(node, message: format(SETTING, named(node))) if setting?(node)
    add_offense(node, message: format(THREAD, slot(node))) if shared?(node) && !seam?(node)
  end

  def on_class(node)
    add_offense(node.parent_class, message: format(CURRENT, node.identifier.source)) if current?(node.parent_class)
  end

  def on_ivasgn(node)
    method = node.each_ancestor(:def, :defs).first
    return if method.nil?
    check(node) if method.defs_type? || method.each_ancestor(:sclass, :class, :module).first&.sclass_type?
  end

  def on_cvasgn(node) = check(node)

  private

  def named(node) = "#{node.method_name} #{node.first_argument&.source}#{", …" if node.arguments.size > 1}"

  def slot(node)
    held = node.receiver.source
    node.method?(:[]) || node.method?(:[]=) ? "#{held}[#{node.first_argument&.source}]" : "#{held}.#{node.method_name}"
  end

  def setting?(node) = node.receiver.nil? && SETTINGS.include?(node.method_name) && !seam?(node)

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
