# frozen_string_literal: true

class RuboCop::Cop::Kata::NoComments < RuboCop::Cop::Base
  extend RuboCop::Cop::AutoCorrector

  MSG = "Say it in the code: rename it, extract it, or name the constant."

  MAGIC = /
    \A\#\s*(frozen_string_literal|encoding|coding|warn_indent|warn_past_scope|shareable_constant_value|rbs_inline):
  /x
  MODELINE = /\A#.*-\*-.*-\*-|\A#\s*(vim?|ex):\s*(set?\s+)?\w+[=:]/
  DIRECTIVE = /
    \A\#\s*(
      rubocop|standard|simplecov|:nocov:|rbs\b|steep|sorbet|typed|typeprof|kimera|hashira|:reek:|
      @type\s|@rbs\b|noinspection\s|language\s*=|erblint|yard:|packwerk
    )|\A\#:\s
  /x
  RDOC = /\A#\s*:(nodoc|doc|stopdoc|startdoc|enddoc|call-seq|yields|markup|section|include|title|main|notnew):/
  YARD = /\A#\s*@!\w/
  TAG = /\A#\s*@!?[a-z]/
  CITATION = %r{
    https?://\S|\b[\w.-]+/[\w.-]+\#\d+\b|[\s(]\#\d+\b|\bGH-\d+\b|\bRFC\s?\d{3,5}\b|
    \bCVE-\d{4}-\d{4,}\b|\bGHSA(-[a-z0-9]{4}){3}\b
  }xi
  NOTICE = /^#\s*(copyright\b|\(c\)\s*\d|spdx-|licen[sc]ed under\b|licen[sc]e:|all rights reserved)/i
  SHEBANG = /\A#!/
  BUILTIN = [MAGIC, MODELINE, DIRECTIVE, RDOC, YARD, NOTICE, SHEBANG].freeze

  def on_new_investigation
    kept = preserved
    allowed = patterns
    processed_source.comments.each do |comment|
      next if kept.include?(comment) || allowed.any? { it.match?(comment.text) }
      add_offense(comment) { |corrector| corrector.remove(removal(comment)) }
    end
  end

  private

  def patterns = BUILTIN + Array(cop_config["AllowedPatterns"]).map { Regexp.new(it) }

  def preserved
    first = processed_source.ast&.first_line || Float::INFINITY
    header = processed_source.comments.take_while { it.source_range.line < first }
    (NOTICE.match?(header.map(&:text).join("\n")) ? header : []) + kept(TAG, "AllowDocumentation") +
      kept(CITATION, "AllowCitations")
  end

  def kept(pattern, key)
    return [] unless cop_config[key]
    processed_source.comments.slice_when { |above, below| below.loc.line != above.loc.line + 1 }
      .select { |block| block.any? { pattern.match?(it.text) } }.flatten
  end

  def removal(comment)
    range = comment.source_range
    indent = range.source_line[0, range.column]
    return line(range) if indent.strip.empty?
    range.with(begin_pos: range.begin_pos - indent[/\s*\z/].length)
  end

  def line(range)
    finish = range.end_pos
    finish += 1 if processed_source.buffer.source[finish] == "\n"
    range.with(begin_pos: range.begin_pos - range.column, end_pos: finish)
  end
end
