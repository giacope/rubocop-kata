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
    later = deferred?(opener, closer, found)
    after(opener, found, later) unless ends?(opener)
    before(closer, leading(opener), later) unless starts?(closer)
  end

  def deferred?(opener, closer, found)
    found.any? { |outer, end_token| inside?(outer, opener) && end_token.pos.end_pos > closer.pos.begin_pos }
  end

  def inside?(outer, inner) = outer.line == inner.line && outer.pos.begin_pos < inner.pos.begin_pos

  def after(token, found, later)
    register(token, later) do |corrector|
      corrector.replace(trailing(token), "\n#{leading(token)}#{STEP}")
      nested(token, found).each { corrector.insert_before(start(it), STEP) }
    end
  end

  def before(token, indent, later)
    register(token, later) { it.replace(preceding(token), "\n#{indent}") }
  end

  def nested(token, found)
    last = found.filter_map { |inner, close| close.line if inside?(token, inner) && close.line > inner.line }.max
    return [] unless last
    ((token.line + 1)..last).reject { blank?(it) || literal?(it) }
  end

  def blank?(line) = processed_source.lines[line - 1].strip.empty?

  def literal?(line)
    position = processed_source.buffer.line_range(line).begin_pos
    strings.any? { it.begin_pos <= position && position < it.end_pos }
  end

  def strings
    @_strings ||= Array(processed_source.ast&.each_node(:str, :dstr, :xstr)).map { span(it) }
  end

  def span(node)
    node.heredoc? ? node.loc.heredoc_body.join(node.loc.heredoc_end) : node.source_range.adjust(begin_pos: 1)
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

  def ends?(token)
    after = rest(token)
    after = after.sub(PARAMETERS, "").strip if BLOCK.include?(token.type)
    after.empty? || after.start_with?("#")
  end

  def rest(token) = processed_source.lines[token.line - 1][(token.column + token.text.length)..].to_s.strip

  def leading(token) = processed_source.lines[token.line - 1][/\A[ \t]*/]

  def register(token, later, &)
    message = format(MSG, token.text)
    later ? add_offense(token.pos, message: message) : add_offense(token.pos, message: message, &)
  end
end
