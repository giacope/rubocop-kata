# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT
# Derived from rubocop-elegant (https://github.com/yegor256/rubocop-elegant), see LICENSE.txt

class RuboCop::Kata::Variable::Ledger
  STATEMENT_PARENTS = %i[begin kwbegin def defs block numblock].freeze

  def initialize(body)
    @body = body
  end

  def pairs
    singles.reject { |assign, read| RuboCop::Kata::Variable::Boundary.new(assign, read).crossed? }.to_h
  end

  private

  def singles
    reads = self.reads
    tainted = self.tainted
    assigns.filter_map { |name, found| single(found, reads.fetch(name, [])) unless tainted.include?(name) }
  end

  def single(found, once) = ([found.first, once.first] if found.size == 1 && once.size == 1)

  def assigns = nodes.select { it.lvasgn_type? && statement?(it) }.group_by { it.children.first }

  def reads = nodes.select(&:lvar_type?).group_by { it.children.first }

  def tainted = nodes.select(&:shorthand_asgn?).map(&:assignment_node).select(&:lvasgn_type?).map(&:name)

  def nodes(node = @body, found = [])
    return found if node.def_type? || node.defs_type?
    found << node
    node.each_child_node { nodes(it, found) }
    found
  end

  def statement?(node)
    STATEMENT_PARENTS.include?(node.each_ancestor.find { !it.begin_type? || it.children.size != 1 }.type)
  end
end
