# frozen_string_literal: true

class Assay::Census
  ENCODING = /\A#.*\bcoding[:=]/i
  KINDS = {
    "magic" => /\A#(!|\s*(frozen_string_literal|shareable_constant_value|warn_indent|typed)\s*:|.*-\*-|\s*vim?:)/,
    "yard" => /\A#\s*@!?[a-z]/,
    "directive" => /\A#\s*(rubocop|standard|simplecov|:nocov:|:nodoc:|steep|rbs|@rbs|:|kimera|hashira|:reek:)/
  }.freeze

  def initialize(root, paths)
    @root = root
    @paths = paths
  end

  def to_h
    kinds = files.flat_map { comments(it) }.map { kind(*it) }.tally.sort.to_h
    { "files" => files.size, "comments" => kinds.values.sum, "kinds" => kinds }
  end

  def broken = files.reject { Prism.parse_file(it).success? }.map { it.delete_prefix("#{@root}/") }

  private

  def files = @paths.flat_map { Dir.glob(File.join(@root, it, "**", "*.rb")) }.sort

  def comments(path) = Prism.parse_file_comments(path).map { [it.location.start_line, it.slice] }

  def kind(line, text)
    return "encoding" if line <= 2 && ENCODING.match?(text)
    KINDS.find { |_, pattern| pattern.match?(text) }&.first || "prose"
  end
end
