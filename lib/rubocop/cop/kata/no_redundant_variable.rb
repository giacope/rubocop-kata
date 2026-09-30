# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT
# Derived from rubocop-elegant (https://github.com/yegor256/rubocop-elegant), see LICENSE.txt

class RuboCop::Cop::Kata::NoRedundantVariable < RuboCop::Cop::Base
  extend RuboCop::Cop::AutoCorrector
  include RuboCop::Cop::RangeHelp

  MSG = 'Variable "%s" is redundant and must be inlined: it is read only once'

  def on_def(node) = check(node.body)

  def on_defs(node) = check(node.body)

  private

  def check(body)
    return if body.nil?
    singles = RuboCop::Kata::Variable::Ledger.new(body).pairs
    movable = singles.select { |assign, _| solo?(assign) && !heredoc?(assign) && !swallows?(assign, singles) }
    gap = RuboCop::Kata::Variable::Gap.new(movable)
    singles.each { |assign, read| register(assign, read, movable) unless gap.crossed?(assign, read) }
  end

  def register(assign, read, movable)
    return inline(assign, read) if movable.key?(assign)
    add_offense(assign, message: format(MSG, assign.children.first))
  end

  def inline(assign, read)
    inlining = RuboCop::Kata::Variable::Inlining.new(assign.children.last, read)
    add_offense(assign, message: format(MSG, assign.children.first)) do |corrector|
      corrector.replace(inlining.range, inlining.text)
      corrector.remove(range_by_whole_lines(assign.source_range, include_final_newline: true))
    end
  end

  def swallows?(assign, singles)
    singles.any? { |_, read| assign.source_range.contains?(read.source_range) }
  end

  def heredoc?(assign) = assign.each_descendant(:str, :dstr, :xstr).any?(&:heredoc?)

  def solo?(assign)
    range = assign.source_range
    range.source_buffer.source_line(range.first_line).strip == range.source.strip
  end
end
