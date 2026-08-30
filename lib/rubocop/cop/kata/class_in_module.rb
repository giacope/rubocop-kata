# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT
# Derived from rubocop-elegant (https://github.com/yegor256/rubocop-elegant), see LICENSE.txt

class RuboCop::Cop::Kata::ClassInModule < RuboCop::Cop::Base
  MSG = "Class %s must be defined inside a module, not globally"
  public_constant :MSG

  def on_class(node)
    return if namespaced?(node)
    return if scoped?(node)
    add_offense(node, message: format(MSG, name: label(node)))
  end

  private

  def namespaced?(node)
    scope = outer(node)
    !scope.nil? && scope.type != :cbase
  end

  def scoped?(node)
    return false unless outer(node).nil?
    node.each_ancestor(:module, :class).any?
  end

  def outer(node)
    node.children[0].children[0]
  end

  def label(node)
    node.children[0].source
  end
end
