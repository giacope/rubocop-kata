# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT
# Derived from rubocop-elegant (https://github.com/yegor256/rubocop-elegant), see LICENSE.txt

class RuboCop::Kata::Variable::Census
  STATEMENT_PARENTS = %i[begin kwbegin def defs block numblock].freeze
  PARAMETERS = %i[arg optarg restarg kwarg kwoptarg kwrestarg blockarg shadowarg].freeze

  def initialize(body, arguments)
    @body = body
    @arguments = arguments
  end

  def assigns = nodes.select { it.lvasgn_type? && statement?(it) }.group_by { it.children.first }

  def reads = nodes.select(&:lvar_type?).group_by { it.children.first }

  def tainted
    shorthand = nodes.select(&:shorthand_asgn?).map(&:assignment_node).select(&:lvasgn_type?)
    [*shorthand, *@arguments.each_node(*PARAMETERS), *nodes.select { PARAMETERS.include?(it.type) }].map(&:name)
  end

  private

  def nodes(node = @body)
    return [] if node.def_type? || node.defs_type?
    [node, *node.each_child_node.flat_map { nodes(it) }]
  end

  def statement?(node)
    STATEMENT_PARENTS.include?(node.each_ancestor.find { !it.begin_type? || it.children.size != 1 }.type)
  end
end
