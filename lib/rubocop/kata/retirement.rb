# frozen_string_literal: true

require "yaml"

class RuboCop::Kata::Retirement
  def initialize(files = RuboCop::ConfigObsoletion.files)
    @files = files
  end

  def kept(profile) = profile.except(*names)

  private

  def names
    @files.flat_map { |file| YAML.safe_load_file(file).values_at("removed", "renamed").compact.flat_map(&:keys) }
  end
end
