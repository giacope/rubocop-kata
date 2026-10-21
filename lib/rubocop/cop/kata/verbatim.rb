# frozen_string_literal: true

module RuboCop::Cop::Kata::Verbatim
  LITERALS = %i[str dstr xstr].freeze

  private

  def verbatim(ast) = ast.each_node(*LITERALS).flat_map { spanned(it).to_a }.to_set

  def spanned(node)
    return heredoc(node) if node.heredoc?
    node.first_line < node.last_line ? ((node.first_line + 1)..node.last_line) : []
  end

  def heredoc(node)
    body = node.loc.heredoc_body
    body.line..body.last_line
  end

  def report(lines) = lines.sort.each { register(it) if processed_source.lines[it - 1].strip.empty? }

  def register(number)
    target = processed_source.buffer.line_range(number)
    add_offense(target) { |corrector| corrector.remove(whole(target)) }
  end

  def whole(target)
    finish = target.end_pos
    finish += 1 if processed_source.buffer.source[finish] == "\n"
    target.with(end_pos: finish)
  end
end
