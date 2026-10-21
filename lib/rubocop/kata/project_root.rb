# frozen_string_literal: true

require "pathname"

class RuboCop::Kata::ProjectRoot
  MARKERS = %w[Gemfile gems.rb *.gemspec config/application.rb].freeze
  CONFIG = ".rubocop.yml"

  def initialize(start)
    @start = start
  end

  def path
    dirs = Pathname(@start).expand_path.ascend.map(&:to_s)
    dirs.find { loads?(it) } || dirs.find { marked?(it) } || @start
  end

  private

  def loads?(dir)
    config = File.join(dir, CONFIG)
    File.file?(config) && File.read(config, encoding: Encoding::UTF_8).scrub.include?("rubocop-kata")
  end

  def marked?(dir) = MARKERS.any? { Dir.glob(it, base: dir).any? }
end
