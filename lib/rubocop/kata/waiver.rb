# frozen_string_literal: true

class RuboCop::Kata::Waiver
  MARKER = "--"
  HEADER = /\A#\s*rubocop\s*:\s*([\w-]+)/
  MODES = %w[disable disable-next disable-next-line todo todo-next].freeze
  SIGNED = %w[push next].freeze

  def initialize(comment)
    @comment = comment
  end

  def disabling? = MODES.include?(mode) || (SIGNED.include?(mode) && cops.any?)

  def cops
    names = body.split(MARKER, 2).first.split(/[\s,]+/).reject(&:empty?)
    SIGNED.include?(mode) ? names.filter_map { it.delete_prefix("-") if it.start_with?("-") } : names
  end

  def line = @comment.loc.line

  def reason = body.split(MARKER, 2)[1].to_s.strip

  private

  def mode = @comment.text[HEADER, 1].to_s

  def body = @comment.text.sub(HEADER, "")
end
