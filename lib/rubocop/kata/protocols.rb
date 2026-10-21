# frozen_string_literal: true

class RuboCop::Kata::Protocols
  SHELF = File.expand_path("../../../data/protocols", __dir__)
  NAMES = Hash.new { |names, key| names[key] = Set.new(File.readlines(File.join(SHELF, "#{key}.txt"), chomp: true)) }

  def initialize(kinds)
    @kinds = kinds
  end

  def include?(name) = @kinds.any? { NAMES[it].include?(name) }
end
