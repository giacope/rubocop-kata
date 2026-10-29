# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT
# Derived from rubocop-elegant (https://github.com/yegor256/rubocop-elegant), see LICENSE.txt

class RuboCop::Cop::Kata::PairedBrackets < RuboCop::Cop::Base
  extend RuboCop::Cop::AutoCorrector
  include RuboCop::Cop::Kata::Verbatim

  MSG = "Bracket %s must be paired on the same line, or start/end its line"

  OPENERS = %i[tLPAREN tLPAREN2 tLPAREN_ARG tLBRACK tLBRACK2 tLCURLY tLBRACE tLBRACE_ARG tLAMBEG].freeze
  CLOSERS = %i[tRPAREN tRBRACK tRCURLY].freeze
  PARAMETERS = /\A\|[^|]*\|/
  STEP = "  "

  def on_new_investigation
    super
    stack = []
    found =
      processed_source.tokens.filter_map do |token|
        stack << token if OPENERS.include?(token.type)
        [stack.pop, token] if CLOSERS.include?(token.type) && !stack.empty?
      end
    found.each { |opener, closer| check(opener, closer, found) }
  end

  private

  def check(opener, closer, found)
    return if opener.line == closer.line
    return defer(opener, closer) if found.any? { |outer, close| enclosing?(outer, close, opener) }
    after(opener, closer, found) unless ends?(opener)
    before(closer, leading(opener)) unless starts?(closer)
  end

  def defer(opener, closer)
    register(opener) unless ends?(opener)
    register(closer) unless starts?(closer)
  end

  def enclosing?(outer, close, inner)
    !outer.equal?(inner) && outer.line == inner.line && outer.pos.join(close.pos).contains?(inner.pos)
  end

  def after(token, closer, found)
    register(token) do |corrector|
      corrector.replace(trailing(token), "\n#{leading(token)}#{STEP}")
      nested(token, closer, found).each { corrector.insert_before(start(it), STEP) }
    end
  end

  def before(token, indent)
    bodies = heredocs.select { it.source_range.line == token.line }
    return register(token) { it.replace(preceding(token), "\n#{indent}") } if bodies.empty?
    return register(token) unless ends?(token)
    register(token) { below(it, token, indent, bodies) }
  end

  def below(corrector, token, indent, bodies)
    corrector.remove(preceding(token).join(token.pos))
    corrector.insert_after(bodies.map { it.loc.heredoc_end }.max_by(&:end_pos), "\n#{indent}#{token.text}")
  end

  def nested(token, closer, found)
    last = found.filter_map { |inner, close| close.line if enclosing?(token, closer, inner) }.max
    return [] unless last
    ((token.line + 1)..last).reject { untouched?(it) }
  end

  def untouched?(line) = processed_source.lines[line - 1].strip.empty? || quoted.include?(line)

  def start(line)
    range = processed_source.buffer.line_range(line)
    range.adjust(begin_pos: range.source[/\A[ \t]*/].length).resize(0)
  end

  def quoted = (@_quoted ||= {}.compare_by_identity)[processed_source] ||= verbatim(processed_source.ast)

  def heredocs = Array(processed_source.ast&.each_node(:str, :dstr, :xstr)).select(&:heredoc?)

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
    rest = processed_source.lines[token.line - 1][token.pos.last_column..].to_s.strip.sub(PARAMETERS, "").strip
    rest.empty? || rest.start_with?("#")
  end

  def leading(token) = processed_source.lines[token.line - 1].chars.take_while { [" ", "\t"].include?(it) }.join

  def register(token, &) = add_offense(token.pos, message: format(MSG, token.text), &)
end
