# frozen_string_literal: true

module RuboCop::Cop::Kata::Verbatim
  LITERALS = %i[str dstr xstr].freeze

  private

  def verbatim
    ast = processed_source.ast
    return Set.new unless ast
    ast.each_node(*LITERALS).flat_map { spanned(it).to_a }.to_set
  end

  def spanned(node)
    return heredoc(node) if node.heredoc?
    node.first_line < node.last_line ? ((node.first_line + 1)..node.last_line) : []
  end

  def heredoc(node)
    body = node.loc.heredoc_body
    body.line..body.last_line
  end
end
