# frozen_string_literal: true

class RuboCop::Cop::Kata::NoComments < RuboCop::Cop::Base
  extend RuboCop::Cop::AutoCorrector

  MSG = "Say it in the code: rename it, extract it, or name the constant."

  MAGIC = /\A#\s*(frozen_string_literal|encoding|coding|warn_indent|shareable_constant_value):/
  DIRECTIVE = /\A#\s*(rubocop|simplecov|rbs|steep|sorbet|typed|:nocov:)/
  RDOC = /\A#\s*:(nodoc|doc|stopdoc|startdoc|enddoc|call-seq|yields|markup|section|include|title|main|notnew):/
  YARD = /\A#\s*@!\w/
  NOTICE = /^#\s*(copyright\b|\(c\)\s*\d|spdx-|licen[sc]ed under\b|licen[sc]e:|all rights reserved)/i
  SHEBANG = /\A#!/

  def on_new_investigation
    header = notice
    processed_source.comments.each { register(it) unless exempt?(it) || header.include?(it) }
  end

  private

  def exempt?(comment)
    text = comment.text
    [MAGIC, DIRECTIVE, RDOC, YARD, NOTICE, SHEBANG].any? { it.match?(text) }
  end

  def notice
    header = preamble
    NOTICE.match?(header.map(&:text).join("\n")) ? header : []
  end

  def preamble
    processed_source.comments.take_while { it.source_range.line < (processed_source.ast&.first_line || Float::INFINITY) }
  end

  def register(comment)
    add_offense(comment) { |corrector| corrector.remove(removal(comment)) }
  end

  def removal(comment)
    range = comment.source_range
    alone?(range) ? line(range) : trailing(range)
  end

  def alone?(range) = range.source_line[0, range.column].strip.empty?

  def line(range)
    finish = range.end_pos
    finish += 1 if processed_source.buffer.source[finish] == "\n"
    range.with(begin_pos: range.begin_pos - range.column, end_pos: finish)
  end

  def trailing(range)
    range.with(begin_pos: range.begin_pos - range.source_line[0, range.column][/\s*\z/].length)
  end
end
