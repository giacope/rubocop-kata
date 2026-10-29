# frozen_string_literal: true

class RuboCop::Kata::Repertoire
  METHOD = /^[ \t]*def[ \t]+(?:self\.)?([a-z_]\w*[?!]?)/
  CALLS = [/\.([a-z_]\w*[?!]?)/, /\b(?:__send__|public_send|send|respond_to\?)\(\s*:([a-z_]\w*[?!]?)/].freeze
  SENDS = [/(?<!def self)\.([a-z_]\w*[?!]?)/, /\b(?:__send__|public_send|send)\(\s*:([a-z_]\w*[?!]?)/].freeze
  SHELVES = Hash.new { |shelves, sources| shelves[sources] = new(sources.texts) }

  def self.of(sources) = SHELVES[sources]

  def initialize(texts)
    @texts = texts
  end

  def message?(name) = messages.include?(name.to_s)

  def foreign?(name) = sent.include?(name.to_s) && !message?(name)

  def sent?(name) = called.include?(name.to_s)

  def owners(name, hidden:)
    replies.fetch(name.to_s, []).filter_map { |owner, _, shown| owner if hidden || shown == :public }
  end

  private

  def messages = @_messages ||= @texts.flat_map { it.scan(METHOD) }.flatten.to_set

  def replies = @_replies ||= @texts.flat_map { RuboCop::Kata::Messages.new(it).records }.group_by { it[1] }

  def sent = @_sent ||= scanned(CALLS)

  def called = @_called ||= scanned(SENDS)

  def scanned(patterns) = @texts.flat_map { |text| patterns.flat_map { text.scan(it) } }.flatten.to_set
end
