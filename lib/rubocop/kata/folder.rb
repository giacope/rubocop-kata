# frozen_string_literal: true

class RuboCop::Kata::Folder
  BOUND = 3000

  def initialize(root)
    @root = root
  end

  def paths(*patterns) = Dir.glob(patterns, base: @root).map { File.join(@root, it) }

  def sources(*patterns) = paths(*patterns).first(BOUND)

  def texts(*patterns) = paths(*patterns).map { read(it) }

  def mentions?(manifests, pattern) = paths(*manifests).any? { pattern.match?(read(it)) }

  private

  def read(path) = File.read(path, encoding: Encoding::UTF_8).scrub
end
