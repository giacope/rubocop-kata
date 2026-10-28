# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT
# Derived from rubocop-elegant (https://github.com/yegor256/rubocop-elegant), see LICENSE.txt

class RuboCop::Cop::Kata::ClassInModule < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster
  include RuboCop::Cop::Kata::Territory
  include RuboCop::Cop::Kata::Reopening

  MSG = "Class %s must be defined inside a module, not globally"
  REOPEN_MSG = "Reopening `%s` patches it for every caller; use a refinement (`refine %s`) or a decorator object"
  public_constant :MSG

  def_node_matcher :migration?, "(const (const {nil? cbase} :ActiveRecord) :Migration)"

  def on_class(node)
    return if namespaced?(node) || scoped?(node) || root?(node.identifier.const_name) || migrated?(node)
    add_offense(node, message: message(node)) if judged?(node)
  end

  private

  def migrated?(node)
    parent = node.parent_class
    [parent, *assigned(parent)].compact.any? { |value| value.each_node(:const).any? { migration?(it) } }
  end

  def assigned(parent)
    return [] unless parent&.const_type? && parent.namespace.nil?
    name = parent.short_name
    processed_source.ast.each_node(:casgn).select { it.namespace.nil? && it.name == name }.map(&:expression)
  end

  def message(node)
    name = node.identifier.short_name.to_s
    return format(MSG, node.identifier.source) unless node.parent_class.nil? && listed?("CoreClasses", name)
    format(REOPEN_MSG, name, name)
  end

  def namespaced?(node) = path(node).any? { !it.cbase_type? }

  def scoped?(node) = path(node).none? && node.each_ancestor(:module, :class).any?

  def path(node) = node.identifier.each_path
end
