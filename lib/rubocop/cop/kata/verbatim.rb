# frozen_string_literal: true

module RuboCop::Cop::Kata::Verbatim
  include RuboCop::Cop::RangeHelp

  LITERALS = %i[str dstr xstr].freeze

  private

  def verbatim(ast) = ast.each_node(*LITERALS).flat_map { spanned(it).to_a }.to_set

  def spanned(node)
    return heredoc(node) if node.heredoc?
    (node.first_line + 1)..node.last_line
  end

  def heredoc(node)
    body = node.loc.heredoc_body
    body.line..body.last_line
  end

  def report(lines) = lines.sort.each { register(it) if processed_source.lines[it - 1].strip.empty? }

  def register(number)
    target = processed_source.buffer.line_range(number)
    add_offense(target) { |corrector| corrector.remove(range_by_whole_lines(target, include_final_newline: true)) }
  end
end
