# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT
# Derived from rubocop-elegant (https://github.com/yegor256/rubocop-elegant), see LICENSE.txt

class RuboCop::Cop::Kata::NoEmptyLinesInMethods < RuboCop::Cop::Base
  extend RuboCop::Cop::AutoCorrector
  include RuboCop::Cop::Kata::Verbatim

  MSG = "Empty line inside method body is not allowed"

  def on_def(node)
    body = node.body
    return if body.nil? || body.single_line?
    (body.first_line..body.last_line).each { register(it) if blank?(it) }
  end

  alias on_defs on_def

  private

  def blank?(number) = !kept.include?(number) && processed_source.lines[number - 1].strip.empty?

  def kept = @_kept ||= verbatim

  def register(number)
    target = processed_source.buffer.line_range(number)
    add_offense(target) { |corrector| corrector.remove(whole(target)) }
  end

  def whole(target)
    finish = target.end_pos
    finish += 1 if processed_source.buffer.source[finish] == "\n"
    target.with(end_pos: finish)
  end
end
