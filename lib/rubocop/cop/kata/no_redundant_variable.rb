# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT
# Derived from rubocop-elegant (https://github.com/yegor256/rubocop-elegant), see LICENSE.txt

class RuboCop::Cop::Kata::NoRedundantVariable < RuboCop::Cop::Base
  extend RuboCop::Cop::AutoCorrector
  include RuboCop::Cop::RangeHelp

  MSG = 'Variable "%s" is redundant and must be inlined: it is read only once'
  LIMIT = 120

  def on_def(node)
    body = node.body
    audit(body, node.arguments.each_node(*RuboCop::Kata::Variable::Ledger::PARAMETERS).to_a) if body
  end

  alias on_defs on_def

  private

  def audit(body, parameters)
    singles = RuboCop::Kata::Variable::Ledger.new(body, parameters).pairs
    plain = singles.reject { |assign, read| explains?(assign) || long?(assign, read) }
    movable = plain.select { |assign, read| movable?(assign, read, singles) }
    gap = RuboCop::Kata::Variable::Gap.new(singles, movable)
    plain.each { |assign, read| register(assign, read, movable) unless gap.crossed?(assign) }
  end

  def explains?(assign) = RuboCop::Kata::Variable::Label.new(assign, sorbet: cop_config["Sorbet"] == true).explains?

  def long?(assign, read)
    limit = config.for_cop("Layout/LineLength")
    return false if limit["Enabled"] == false
    width(RuboCop::Kata::Variable::Inlining.new(assign.expression, read)) > limit.fetch("Max", LIMIT)
  end

  def width(inlining)
    range = inlining.range
    line = range.source_line
    joined = "#{line[0, range.column]}#{inlining.text}#{line[range.last_column..]}".lines
    [joined.first, joined.last].map { it.chomp.length }.max
  end

  def register(assign, read, movable)
    return inline(assign, read) if movable.key?(assign)
    add_offense(assign, message: format(MSG, assign.name))
  end

  def inline(assign, read)
    inlining = RuboCop::Kata::Variable::Inlining.new(assign.expression, read)
    add_offense(assign, message: format(MSG, assign.name)) do |corrector|
      corrector.replace(inlining.range, inlining.text)
      corrector.remove(range_by_whole_lines(assign.source_range, include_final_newline: true))
    end
  end

  def swallows?(assign, singles)
    singles.any? { |_, read| assign.source_range.contains?(read.source_range) }
  end

  def movable?(assign, read, singles)
    solo?(assign) && !heredoc?(assign) && !swallows?(assign, singles) && faithful?(assign, read)
  end

  def faithful?(assign, read) = RuboCop::Kata::Variable::Inlining.new(assign.expression, read).faithful?

  def heredoc?(assign) = assign.each_descendant(:str, :dstr, :xstr).any?(&:heredoc?)

  def solo?(assign)
    range = assign.source_range
    range.source_buffer.source_line(range.first_line).strip == range.source.strip
  end
end
