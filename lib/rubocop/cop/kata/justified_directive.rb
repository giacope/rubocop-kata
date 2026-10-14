# frozen_string_literal: true

class RuboCop::Cop::Kata::JustifiedDirective < RuboCop::Cop::Base
  MSG = "Say why after `--`: `# rubocop:disable %s -- <reason>`; a reason of at least %d words."

  def on_new_investigation
    processed_source.comments.each { check(it) }
  end

  private

  def check(comment)
    waiver = RuboCop::Kata::Waiver.new(comment)
    return unless waiver.disabling?
    add_offense(comment, message: format(MSG, waiver.cops.join(", "), minimum)) unless reasoned?(waiver)
  end

  def reasoned?(waiver) = waiver.reason.split.size >= minimum

  def minimum = Integer(cop_config.fetch("MinWords", 3))
end
