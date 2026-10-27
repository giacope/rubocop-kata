# frozen_string_literal: true

class RuboCop::Kata::Inventory
  METHOD = /^[ \t]*def[ \t]+(?:self\.)?([a-z_]\w*[?!]?)/
  CALLS = [/\.([a-z_]\w*[?!]?)/, /\b(?:__send__|public_send|send|respond_to\?)\(\s*:([a-z_]\w*[?!]?)/].freeze
  SENDS = [/(?<!def self)\.([a-z_]\w*[?!]?)/, /\b(?:__send__|public_send|send)\(\s*:([a-z_]\w*[?!]?)/].freeze

  SHELVES = Hash.new { |shelves, key| shelves[key] = new(*key) }

  def self.of(root, patterns) = SHELVES[[root, patterns]]

  def initialize(root, patterns)
    @root = root
    @patterns = patterns
  end

  def type?(name) = types.include?(name.to_s)

  def namespace?(name) = types.any? { it.start_with?("#{name}::") }

  def message?(name) = messages.include?(name.to_s)

  def foreign?(name) = sent.include?(name.to_s) && !message?(name)

  def sent?(name) = called.include?(name.to_s)

  def owners(name, hidden:)
    replies.fetch(name.to_s, []).filter_map { |owner, _, shown| owner if hidden || shown == :public }
  end

  def openings(name) = opened.fetch(name, [])

  def hooks = @_hooks ||= texts.flat_map { RuboCop::Kata::Kinship.parse(it).hooks }

  def defining(name)
    spelled = /\bdef\s+(?:self\.)?#{Regexp.escape(name)}(?![\w?!=])/
    files.select { spelled.match?(it.last) }.flat_map { trees[it.first].each_node(:def, :defs).to_a }
      .select { it.method_name.to_s == name }
  end

  def lineage
    @_lineage ||= texts.map { RuboCop::Kata::Lineage.parse(it) }.reduce(RuboCop::Kata::Lineage.new({}), :merge)
  end

  private

  def types
    @_types ||= texts.each_with_object(Set.new) { |text, found| found.merge(definitions(text)) }
  end

  def definitions(text) = RuboCop::Kata::Definitions.new(text).names

  def messages = @_messages ||= texts.flat_map { it.scan(METHOD) }.flatten.to_set

  def opened = @_opened ||= files.flat_map { RuboCop::Kata::Openings.new(*it).records }.group_by(&:first)

  def replies = @_replies ||= texts.flat_map { RuboCop::Kata::Messages.new(it).records }.group_by { it[1] }

  def sent = @_sent ||= scanned(CALLS)

  def called = @_called ||= scanned(SENDS)

  def scanned(patterns) = texts.flat_map { |text| patterns.flat_map { text.scan(it) } }.flatten.to_set

  def texts = files.map(&:last)

  def trees
    @_trees ||=
      Hash.new do |trees, path|
        parsed = RuboCop::ProcessedSource.new(files.to_h.fetch(path), 3.4, path, parser_engine: :parser_prism)
        trees[path] = parsed.ast || RuboCop::AST::Node.new(:begin)
      end
  end

  def files
    @_files ||= @patterns.flat_map { Dir.glob(it, base: @root) }.uniq
      .map { [it, File.read(File.join(@root, it), encoding: Encoding::UTF_8).scrub] }
  end
end
