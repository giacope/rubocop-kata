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

  def tainted
    nodes.select { it.op_asgn_type? || it.or_asgn_type? || it.and_asgn_type? }.map { it.children.first }
      .select { it.is_a?(RuboCop::AST::Node) && it.lvasgn_type? }.map { it.children.first }
  end

  def nodes(node = @body, found = [])
    return found unless node.is_a?(RuboCop::AST::Node) && !node.def_type? && !node.defs_type?
    found << node
    node.each_child_node { nodes(it, found) }
    found
  end

  def statement?(node)
    return false unless node.children.size == 2
    parent = node.parent
    parent = parent.parent while !parent.nil? && parent.type == :begin && parent.children.size == 1
    !parent.nil? && STATEMENT_PARENTS.include?(parent.type)
  end
end
