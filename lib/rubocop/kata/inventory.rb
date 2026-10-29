# frozen_string_literal: true

class RuboCop::Kata::Inventory
  SHELVES = Hash.new { |shelves, key| shelves[key] = new(RuboCop::Kata::Sources.of(*key)) }

  def self.of(root, patterns) = SHELVES[[root, patterns]]

  def initialize(sources)
    @sources = sources
  end

  def type?(name) = types.include?(name.to_s)

  def namespace?(name) = types.any? { it.start_with?("#{name}::") }

  def openings(name) = opened.fetch(name, [])

  def hooks = @_hooks ||= @sources.texts.flat_map { RuboCop::Kata::Kinship.parse(it).hooks }

  private

  def types
    @_types ||= @sources.texts.each_with_object(Set.new) { |text, found| found.merge(definitions(text)) }
  end

  def definitions(text) = RuboCop::Kata::Definitions.new(text).names

  def opened = @_opened ||= @sources.files.flat_map { RuboCop::Kata::Openings.new(*it).records }.group_by(&:first)
end
