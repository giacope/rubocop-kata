# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT
# Derived from rubocop-elegant (https://github.com/yegor256/rubocop-elegant), see LICENSE.txt

class RuboCop::Cop::Kata::NoEmptyLinesInBlocks < RuboCop::Cop::Base
  extend RuboCop::Cop::AutoCorrector
  include RuboCop::Cop::Kata::Verbatim

  MSG = "Empty line inside block body is not allowed"
  HOLDERS = %i[block numblock itblock if while until for case case_match kwbegin].freeze

  def on_new_investigation
    ast = processed_source.ast
    return unless ast
    inside = ast.each_node(*HOLDERS).flat_map { ((it.first_line + 1)..(it.last_line - 1)).to_a }
    report(inside.to_set - verbatim(ast) - gaps(ast))
  end

  private

  def gaps(ast) = ast.each_node(:def, :defs).flat_map { between(it).to_a }.to_set

  def between(node)
    sibling = node.right_sibling
    return [] unless sibling.is_a?(RuboCop::AST::Node) && %i[def defs].include?(sibling.type)
    (node.last_line + 1)..(sibling.first_line - 1)
  end
end
