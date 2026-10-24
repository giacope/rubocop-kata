# frozen_string_literal: true

module RuboCop::Cop::Kata::Verbatim
  include RuboCop::Cop::RangeHelp

  LITERALS = %i[str dstr xstr].freeze
  CONTINUATION = /(?<!\\)(?:\\\\)*\\\z/

  private

  def verbatim(ast) = ast.each_node(*LITERALS).flat_map { spanned(it).to_a }.to_set

  def spanned(node)
    return heredoc(node) if node.heredoc?
    (node.first_line + 1)..node.last_line
  end

  def heredoc(node) = node.loc.heredoc_body.line..node.loc.heredoc_end.line

  def report(lines) = lines.sort.each { register(it) if processed_source.lines[it - 1].strip.empty? }

  def register(number)
    target = processed_source.buffer.line_range(number)
    return add_offense(target) if continued?(number - 1) || commented?(number)
    add_offense(target) { |corrector| corrector.remove(range_by_whole_lines(target, include_final_newline: true)) }
  end

  def continued?(number)
    processed_source.lines[number - 1].match?(CONTINUATION) && !processed_source.comment_at_line(number)
  end

  def commented?(number) = processed_source.comments.any? { spanned_lines(it).cover?(number) }

  def spanned_lines(comment) = comment.loc.line...(comment.loc.line + comment.text.lines.size)
end
