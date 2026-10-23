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

  def on_class(node)
    return if namespaced?(node) || scoped?(node) || root?(node.identifier.const_name) || !judged?(node)
    add_offense(node, message: message(node))
  end

  private

  def message(node)
    name = node.identifier.short_name.to_s
    return format(MSG, node.identifier.source) unless node.parent_class.nil? && listed?("CoreClasses", name)
    format(REOPEN_MSG, name, name)
  end

  def namespaced?(node) = path(node).any? { !it.cbase_type? }

  def scoped?(node) = path(node).none? && node.each_ancestor(:module, :class).any?

  def path(node) = node.identifier.each_path
end
