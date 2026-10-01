# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT
# Derived from rubocop-elegant (https://github.com/yegor256/rubocop-elegant), see LICENSE.txt

class RuboCop::Cop::Kata::PairedBrackets < RuboCop::Cop::Base
  extend RuboCop::Cop::AutoCorrector

  MSG = "Bracket %s must be paired on the same line, or start/end its line"

  OPENERS = %i[tLPAREN tLPAREN2 tLPAREN_ARG tLBRACK tLBRACK2 tLCURLY tLBRACE tLBRACE_ARG tLAMBEG].freeze
  CLOSERS = %i[tRPAREN tRBRACK tRCURLY].freeze

  def on_new_investigation
    super
    pairs.each { |opener, closer| check(opener, closer) }
  end

  private

  def pairs
    stack = []
    processed_source.tokens.filter_map { pair(it, stack) }
  end

  def pair(token, stack)
    type = token.type
    stack << token if OPENERS.include?(type)
    [stack.pop, token] if CLOSERS.include?(type) && !stack.empty?
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
    edge = token.pos.end
    edge.resize(edge.source_line[edge.column..][/\A[ \t]*/].length)
  end

  def preceding(token)
    edge = token.pos.begin
    edge.adjust(begin_pos: -edge.source_line[0, edge.column][/[ \t]*\z/].length)
  end

  def starts?(token) = processed_source.lines[token.line - 1][0...token.column].strip.empty?

  def ends?(token)
    after = processed_source.lines[token.line - 1][(token.column + token.text.length)..].to_s.strip
    after.empty? || after.start_with?("#")
  end

  def leading(token) = processed_source.lines[token.line - 1][/\A[ \t]*/]

  def register(token, &) = add_offense(token.pos, message: format(MSG, token.text), &)
end
