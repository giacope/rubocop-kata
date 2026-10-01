# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT
# Derived from rubocop-elegant (https://github.com/yegor256/rubocop-elegant), see LICENSE.txt

class RuboCop::Cop::Kata::ClassInModule < RuboCop::Cop::Base
  MSG = "Class %s must be defined inside a module, not globally"
  public_constant :MSG

  def on_class(node)
    return if namespaced?(node) || scoped?(node)
    add_offense(node, message: format(MSG, node.identifier.source))
  end

  private

  def namespaced?(node) = path(node).any? { !it.cbase_type? }

  def scoped?(node) = path(node).none? && node.each_ancestor(:module, :class).any?

  def path(node) = node.identifier.each_path
end
