# frozen_string_literal: true

class RuboCop::Kata::Inventory
  DEFINITION = /^[ \t]*(?:class|module)[ \t]+(?:::)?((?:[A-Z]\w*::)*[A-Z]\w*)/
  ASSIGNMENT = /^[ \t]*((?:[A-Z]\w*::)*[A-Z]\w*)[ \t]*=\s*(?:Class\.new|Module\.new|Struct\.new|Data\.define)\b/
  METHOD = /^[ \t]*def[ \t]+(?:self\.)?([a-z_]\w*[?!]?)/

  SHELVES = Hash.new { |shelves, key| shelves[key] = new(*key) }

  def self.of(root, patterns) = SHELVES[[root, patterns]]

  def initialize(root, patterns)
    @root = root
    @patterns = patterns
  end

  def type?(name) = types.include?(name.to_s.split("::").last)

  def message?(name) = messages.include?(name.to_s)

  private

  def types = @_types ||= scan { it.scan(DEFINITION) + it.scan(ASSIGNMENT) }.flat_map { it.split("::") }.to_set

  def messages = @_messages ||= scan { it.scan(METHOD) }

  def scan(&)
    files.flat_map { |path| yield(File.read(path, encoding: Encoding::UTF_8).scrub).flatten }.to_set
  end

  def files = @patterns.flat_map { Dir.glob(it, base: @root).map { |path| File.join(@root, path) } }.uniq
end
