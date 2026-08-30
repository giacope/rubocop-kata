# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT
# Derived from rubocop-elegant (https://github.com/yegor256/rubocop-elegant), see LICENSE.txt

class RuboCop::Cop::Kata::PairedBrackets < RuboCop::Cop::Base
  extend RuboCop::Cop::AutoCorrector

  MSG = "Bracket %s must be paired on the same line, or start/end its line"

  OPENERS = %i[tLPAREN tLPAREN2 tLPAREN_ARG tLBRACK tLBRACK2 tLCURLY tLBRACE tLBRACE_ARG].freeze
  CLOSERS = %i[tRPAREN tRBRACK tRCURLY].freeze
  BLANKS = [" ", "\t"].freeze

  def on_new_investigation
    super
    pairs.each { |opener, closer| check(opener, closer) }
  end

  private

  def pairs
    stack = []
    processed_source.tokens.each_with_object([]) do |token, found|
      stack << token if OPENERS.include?(token.type)
      found << [stack.pop, token] if CLOSERS.include?(token.type) && !stack.empty?
    end
  end

  def check(opener, closer)
    return if opener.line == closer.line
    indent = leading(opener)
    after(opener, indent) unless ends?(opener)
    before(closer, indent) unless starts?(closer)
  end

  def after(token, indent)
    register(token) { it.replace(trailing(token), "\n#{indent}  ") }
  end

  def before(token, indent)
    register(token) { it.replace(preceding(token), "\n#{indent}") }
  end

  def trailing(token)
    text = processed_source.buffer.source
    stop = token.pos.end_pos
    stop += 1 while BLANKS.include?(text[stop])
    token.pos.end.resize(stop - token.pos.end_pos)
  end

  def preceding(token)
    text = processed_source.buffer.source
    from = token.pos.begin_pos
    from -= 1 while from.positive? && BLANKS.include?(text[from - 1])
    token.pos.begin.adjust(begin_pos: from - token.pos.begin_pos)
  end

  def starts?(token) = processed_source.lines[token.line - 1][0...token.column].strip.empty?

  def ends?(token)
    after = processed_source.lines[token.line - 1][(token.column + token.text.length)..].to_s.strip
    after.empty? || after.start_with?("#")
  end

  def leading(token) = processed_source.lines[token.line - 1][/\A[ \t]*/]

  def register(token, &) = add_offense(token.pos, message: format(MSG, token.text), &)
end
