# frozen_string_literal: true

class RuboCop::Cop::Kata::NoSingleton < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster

  MIXIN = "`include Singleton` makes one global instance; build the object where it is needed and pass it in."
  CACHE = "`%s ||=` keeps one global instance on the class; build the object where it is needed and pass it in."

  RESTRICT_ON_SEND = %i[include].freeze

  def_node_matcher :singleton?, "(send nil? :include (const {nil? cbase} :Singleton))"
  def_node_search :makers, "(send ${nil? self const} :new ...)"

  def on_send(node)
    add_offense(node, message: MIXIN) if singleton?(node)
  end

  def on_ivasgn(node)
    method = node.each_ancestor(:def, :defs).first
    return if method.nil?
    check(node) if method.defs_type? || method.each_ancestor(:sclass, :class, :module).first&.sclass_type?
  end

  def on_cvasgn(node) = check(node)

  private

  def check(node)
    holder = node.parent
    return unless holder&.or_asgn_type?
    return unless node.each_ancestor(:def, :defs).first&.method?(:instance) || instance?(holder.children[1])
    add_offense(holder, message: format(CACHE, node.children.first))
  end

  def instance?(value) = makers(value).any? { !value?(it) }

  def value?(maker) = maker&.const_type? && listed?("AllowedConstructors", maker.const_name)
end
