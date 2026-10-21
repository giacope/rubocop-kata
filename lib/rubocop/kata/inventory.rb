# frozen_string_literal: true

class RuboCop::Kata::Inventory
  METHOD = /^[ \t]*def[ \t]+(?:self\.)?([a-z_]\w*[?!]?)/
  CALLS = [/\.([a-z_]\w*[?!]?)/, /\b(?:__send__|public_send|send|respond_to\?)\(\s*:([a-z_]\w*[?!]?)/].freeze

  SHELVES = Hash.new { |shelves, key| shelves[key] = new(*key) }

  def self.of(root, patterns) = SHELVES[[root, patterns]]

  def initialize(root, patterns)
    @root = root
    @patterns = patterns
  end

  def type?(name) = types.include?(name.to_s)

  def message?(name) = messages.include?(name.to_s)

  def foreign?(name) = sent.include?(name.to_s) && !message?(name)

  def lineage
    @_lineage ||= texts.map { RuboCop::Kata::Lineage.parse(it) }.reduce(RuboCop::Kata::Lineage.new({}), :merge)
  end

  private

  def types
    @_types ||= texts.each_with_object(Set.new) { |text, found| found.merge(definitions(text)) }
  end

  def definitions(text) = RuboCop::Kata::Definitions.new(text).names

  def messages = @_messages ||= texts.flat_map { it.scan(METHOD) }.flatten.to_set

  def sent = @_sent ||= texts.flat_map { |text| CALLS.flat_map { text.scan(it) } }.flatten.to_set

  def texts
    @_texts ||= @patterns.flat_map { Dir.glob(it, base: @root) }.uniq
      .map { File.read(File.join(@root, it), encoding: Encoding::UTF_8).scrub }
  end
end
