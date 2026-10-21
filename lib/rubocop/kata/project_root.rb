# frozen_string_literal: true

require "pathname"

class RuboCop::Kata::ProjectRoot
  MARKERS = %w[Gemfile gems.rb *.gemspec config/application.rb].freeze

  def initialize(start)
    @start = start
  end

  def path = Pathname(@start).expand_path.ascend.map(&:to_s).find { marked?(it) } || @start

  private

  def marked?(dir) = MARKERS.any? { Dir.glob(it, base: dir).any? }
end
