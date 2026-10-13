# frozen_string_literal: true

class RuboCop::Kata::Waiver
  MARKER = "--"
  HEADER = /\A#\s*rubocop\s*:\s*[\w-]+\s*/

  def initialize(comment)
    @comment = comment
  end

  def disabling? = directive.start_with_marker? && directive.disabled?

  def all? = directive.all_cops?

  def cops = match.to_s.sub(HEADER, "").split(/[\s,]+/)

  def line = directive.line_number

  def reason
    tail = match&.post_match.to_s.lstrip
    return unless tail.start_with?(MARKER)
    text = tail.delete_prefix(MARKER).strip
    text unless text.empty?
  end

  private

  def match = @comment.text.match(RuboCop::DirectiveComment::DIRECTIVE_COMMENT_REGEXP)

  def directive = @_directive ||= RuboCop::DirectiveComment.new(@comment)
end
