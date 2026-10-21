# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT
# Derived from rubocop-elegant (https://github.com/yegor256/rubocop-elegant), see LICENSE.txt

class RuboCop::Kata::Variable::Ledger
  STATEMENT_PARENTS = %i[begin kwbegin def defs block numblock].freeze
  PARAMETERS = %i[arg optarg restarg kwarg kwoptarg kwrestarg blockarg shadowarg].freeze

  def initialize(body, parameters = [])
    @body = body
    @parameters = parameters
  end

  # hashira:disable-next-line fragmentation -- blind raters preferred single, the one-read rule, to the merge
  def pairs
    singles.reject { |assign, read| RuboCop::Kata::Variable::Boundary.new(assign, read).crossed? }.to_h
  end

  private

  def singles
    reads = self.reads
    tainted = self.tainted
    assigns.filter_map { |name, found| single(found, reads.fetch(name, [])) unless tainted.include?(name) }
  end

  def single(found, once)
    assign = found.first
    read = once.first
    [assign, read] if found.size == 1 && once.size == 1 && read.source_range.begin_pos >= assign.source_range.end_pos
  end

  def assigns = nodes.select { it.lvasgn_type? && statement?(it) }.group_by { it.children.first }

  def reads = nodes.select(&:lvar_type?).group_by { it.children.first }

  def tainted
    shorthand = nodes.select(&:shorthand_asgn?).map(&:assignment_node).select(&:lvasgn_type?)
    [*shorthand, *@parameters, *nodes.select { PARAMETERS.include?(it.type) }].map(&:name)
  end

  def nodes(node = @body)
    return [] if node.def_type? || node.defs_type?
    [node, *node.each_child_node.flat_map { nodes(it) }]
  end

  def statement?(node)
    STATEMENT_PARENTS.include?(node.each_ancestor.find { !it.begin_type? || it.children.size != 1 }.type)
  end
end
