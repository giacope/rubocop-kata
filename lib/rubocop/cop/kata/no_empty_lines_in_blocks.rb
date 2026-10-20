# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT
# Derived from rubocop-elegant (https://github.com/yegor256/rubocop-elegant), see LICENSE.txt

class RuboCop::Cop::Kata::NoEmptyLinesInBlocks < RuboCop::Cop::Base
  extend RuboCop::Cop::AutoCorrector
  include RuboCop::Cop::Kata::Verbatim

  MSG = "Empty line inside block body is not allowed"
  HOLDERS = %i[block numblock itblock if while until for case case_match kwbegin].freeze

  HOLDERS.each { define_method(:"on_#{it}") { |node| check(node) } }

  private

  def check(node)
    ((node.first_line + 1)..(node.last_line - 1)).each { register(it) if blank?(it) }
  end

  def blank?(number) = !kept.include?(number) && processed_source.lines[number - 1].strip.empty?

  def kept = @_kept ||= verbatim | gaps

  def reported = @_reported ||= Set.new

  def gaps
    ast = processed_source.ast
    return Set.new unless ast
    ast.each_node(:def, :defs).flat_map { between(it).to_a }.to_set
  end

  def between(node)
    sibling = node.right_sibling
    return [] unless sibling.is_a?(RuboCop::AST::Node) && %i[def defs].include?(sibling.type)
    (node.last_line + 1)..(sibling.first_line - 1)
  end

  def register(number)
    return unless reported.add?(number)
    target = processed_source.buffer.line_range(number)
    add_offense(target) { |corrector| corrector.remove(whole(target)) }
  end

  def whole(target)
    finish = target.end_pos
    finish += 1 if processed_source.buffer.source[finish] == "\n"
    target.with(end_pos: finish)
  end
end
