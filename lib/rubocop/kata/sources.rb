# frozen_string_literal: true

class RuboCop::Kata::Sources
  SHELVES = Hash.new { |shelves, key| shelves[key] = new(*key) }

  def self.of(root, patterns) = SHELVES[[root, patterns]]

  def initialize(root, patterns)
    @root = root
    @patterns = patterns
  end

  def texts = files.map(&:last)

  def files
    @_files ||= @patterns.flat_map { Dir.glob(it, base: @root) }.uniq
      .map { [it, File.read(File.join(@root, it), encoding: Encoding::UTF_8).scrub] }
  end

  def defining(name, inspected)
    spelled = /\bdef\s+(?:self\.)?#{Regexp.escape(name)}(?![\w?!=])/
    elsewhere(inspected).select { spelled.match?(it.last) }.flat_map { trees[it.first].each_node(:def, :defs).to_a }
      .select { it.method_name.to_s == name }
  end

  def lineage
    @_lineage ||= texts.map { RuboCop::Kata::Lineage.parse(it) }.reduce(RuboCop::Kata::Lineage.new({}), :merge)
  end

  private

  def elsewhere(inspected) = files.reject { File.expand_path(it.first, @root) == File.expand_path(inspected, @root) }

  def trees
    @_trees ||=
      Hash.new do |trees, path|
        parsed = RuboCop::ProcessedSource.new(files.to_h.fetch(path), 3.4, path, parser_engine: :parser_prism)
        trees[path] = parsed.ast || RuboCop::AST::Node.new(:begin)
      end
  end
end
