# frozen_string_literal: true

class Assay::Census
  KINDS = {
    "encoding" => /\A#.*\bcoding[:=]/i,
    "magic" => /\A#(!|\s*(frozen_string_literal|shareable_constant_value|warn_indent|warn_past_scope|typed)\s*:|.*-\*-|\s*vim?:)/,
    "yard" => /\A#\s*@!?[a-z]/,
    "directive" => /\A#\s*(rubocop|standard|simplecov|:nocov:|:nodoc:|steep|rbs|@rbs|:|kimera|hashira|:reek:)/
  }.freeze

  def initialize(root, paths)
    @root = root
    @paths = paths
  end

  def tally
    kinds = Hash.new(0)
    files.each { |path| comments(path).each { kinds[kind(it)] += 1 } }
    { "files" => files.size, "comments" => kinds.values.sum, "kinds" => kinds.sort.to_h }
  end

  def broken = files.reject { Prism.parse_file(it).success? }.map { it.delete_prefix("#{@root}/") }

  private

  def files = @paths.flat_map { Dir.glob(File.join(@root, it, "**", "*.rb")) }.sort

  def comments(path) = Prism.parse_file_comments(path).map { [it.location.start_line, it.slice] }

  def kind(comment)
    line, text = comment
    return "encoding" if line <= 2 && KINDS.fetch("encoding").match?(text)
    KINDS.except("encoding").find { |_, pattern| pattern.match?(text) }&.first || "prose"
  end
end
