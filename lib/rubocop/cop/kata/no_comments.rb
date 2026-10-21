# frozen_string_literal: true

class RuboCop::Cop::Kata::NoComments < RuboCop::Cop::Base
  extend RuboCop::Cop::AutoCorrector

  MSG = "Say it in the code: rename it, extract it, or name the constant."

  MAGIC = /
    \A\#\s*(
      frozen[-_]string[-_]literal|encoding|coding|warn[-_]indent|warn[-_]past[-_]scope|
      shareable[-_]constant[-_]value|rbs[-_]inline
    )\s*:
  /xi
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

  # hashira:disable-next-line fragmentation -- blind raters preferred its named kept categories to the merge
  def on_new_investigation
    runs = blocks
    kept = notice + documented(runs) + cited(runs)
    runs.each do |block|
      prose = block.reject { exempt?(it) || kept.include?(it) }
      register(prose) unless prose.empty?
    end
  end

  private

  def exempt?(comment)
    text = comment.text
    [MAGIC, MODELINE, DIRECTIVE, RDOC, YARD, NOTICE, SHEBANG, *patterns].any? { it.match?(text) }
  end

  def patterns = Array(cop_config["AllowedPatterns"]).map { Regexp.new(it) }

  def documented(runs)
    return [] unless cop_config["AllowDocumentation"]
    entries = RuboCop::Kata::PublicApi.new(processed_source.ast).lines
    kept(runs, TAG) | runs.select { heading?(it.last, entries) }.flatten
  end

  def heading?(comment, entries) = entries.include?(comment.loc.line + 1) && alone?(comment.source_range)

  def cited(runs) = cop_config["AllowCitations"] ? kept(runs, CITATION) : []

  def kept(runs, pattern) = runs.select { |block| block.any? { pattern.match?(it.text) } }.flatten

  def blocks = processed_source.comments.slice_when { |above, below| !run?(above, below) }.to_a

  def run?(above, below)
    below.loc.line == above.loc.line + 1 && [above, below].all? { alone?(it.source_range) }
  end

  def notice
    header = preamble
    NOTICE.match?(header.map(&:text).join("\n")) ? header : []
  end

  def preamble
    first = processed_source.ast&.first_line || Float::INFINITY
    processed_source.comments.take_while { it.source_range.line < first }
  end

  def register(prose)
    span = prose.first.source_range.join(prose.last.source_range)
    add_offense(span) { |corrector| prose.each { corrector.remove(removal(it)) } }
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
