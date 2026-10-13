# frozen_string_literal: true

class RuboCop::Kata::Waiver
  MARKER = "--"
  HEADER = /\A#\s*rubocop\s*:\s*([\w-]+)/
  MODES = %w[disable disable-next-line todo].freeze

  def initialize(comment)
    @comment = comment
  end

  def disabling? = MODES.include?(@comment.text[HEADER, 1])

  def cops = body.split(MARKER, 2).first.split(/[\s,]+/).reject(&:empty?)

  def line = @comment.loc.line

  def reason = body.split(MARKER, 2)[1].to_s.strip

  private

  def body = @comment.text.sub(HEADER, "")
end
