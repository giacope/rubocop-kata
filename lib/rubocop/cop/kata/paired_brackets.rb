# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT
# Derived from rubocop-elegant (https://github.com/yegor256/rubocop-elegant), see LICENSE.txt

class RuboCop::Cop::Kata::PairedBrackets < RuboCop::Cop::Base
  extend RuboCop::Cop::AutoCorrector

  MSG = "Bracket %s must be paired on the same line, or start/end its line"

  OPENERS = %i[tLPAREN tLPAREN2 tLPAREN_ARG tLBRACK tLBRACK2 tLCURLY tLBRACE tLBRACE_ARG tLAMBEG].freeze
  CLOSERS = %i[tRPAREN tRBRACK tRCURLY].freeze
  BLOCK = %i[tLCURLY tLAMBEG].freeze
  PARAMETERS = /\A\|[^|]*\|/
  STEP = "  "

  def on_new_investigation
    super
    @_strings = nil
    found = pairs
    found.each { |opener, closer| check(opener, closer, found) }
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

  def check(opener, closer, found)
    return if opener.line == closer.line
    return defer(opener, closer) if deferred?(opener, closer, found)
    after(opener, found) unless ends?(opener)
    before(closer, leading(opener)) unless starts?(closer)
  end

  def defer(opener, closer)
    report(opener) unless ends?(opener)
    report(closer) unless starts?(closer)
  end

  def deferred?(opener, closer, found)
    found.any? { |outer, end_token| inside?(outer, opener) && end_token.pos.end_pos > closer.pos.begin_pos }
  end

  def inside?(outer, inner) = outer.line == inner.line && outer.pos.begin_pos < inner.pos.begin_pos

  def after(token, found)
    register(token) do |corrector|
      corrector.replace(trailing(token), "\n#{leading(token)}#{STEP}")
      nested(token, found).each { corrector.insert_before(start(it), STEP) }
    end
  end

  def before(token, indent)
    register(token) { it.replace(preceding(token), "\n#{indent}") }
  end

  def nested(token, found)
    last = found.filter_map { |inner, close| spanned(token, inner, close.line) }.max
    return [] unless last
    ((token.line + 1)..last).reject { blank?(it) || literal?(it) }
  end

  def spanned(token, inner, line) = (line if inside?(token, inner) && line > inner.line)

  def blank?(line) = processed_source.lines[line - 1].strip.empty?

  def literal?(line)
    position = processed_source.buffer.line_range(line).begin_pos
    strings.any? { it.begin_pos <= position && position < it.end_pos }
  end

  def strings
    @_strings ||= Array(processed_source.ast&.each_node(:str, :dstr, :xstr)).map { span(it) }
  end

  def span(node)
    location = node.loc
    node.heredoc? ? location.heredoc_body.join(location.heredoc_end) : node.source_range.adjust(begin_pos: 1)
  end

  def start(line) = processed_source.buffer.line_range(line).resize(0)

  def trailing(token)
    edge = token.pos.end
    edge.resize(edge.source_line[edge.column..][/\A[ \t]*/].length)
  end

  def preceding(token)
    edge = token.pos.begin
    edge.adjust(begin_pos: -edge.source_line[0, edge.column][/[ \t]*\z/].length)
  end

  def starts?(token) = processed_source.lines[token.line - 1][0...token.column].strip.empty?

  def ends?(token) = idle?(trimmed(remainder(token.line, token.pos.last_column), token.type))

  def trimmed(after, type) = BLOCK.include?(type) ? after.sub(PARAMETERS, "").strip : after

  def idle?(after) = after.empty? || after.start_with?("#")

  def remainder(line, column) = processed_source.lines[line - 1][column..].to_s.strip

  def leading(token) = processed_source.lines[token.line - 1][/\A[ \t]*/]

  def register(token, &) = add_offense(token.pos, message: format(MSG, token.text), &)

  def report(token) = add_offense(token.pos, message: format(MSG, token.text))
end
