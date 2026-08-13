# frozen_string_literal: true

require "lint_roller"

class RuboCop::Kata::Plugin < LintRoller::Plugin
  def about
    LintRoller::About.new(
      name: "rubocop-kata", version: RuboCop::Kata::VERSION, homepage: "https://github.com/giacope/rubocop-kata",
      description: "Practiced forms for Ruby: opinionated defaults and fourteen house cops."
    )
  end

  def supported?(context) = context.engine == :rubocop

  def rules(_context)
    LintRoller::Rules.new(
      type: :path,
      config_format: :rubocop,
      value: Pathname.new(__dir__).join("../../../config/default.yml")
    )
  end
end
