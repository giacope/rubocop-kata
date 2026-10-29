# frozen_string_literal: true

class RuboCop::Kata::Origin
  GRAMMARS = %w[rl y racc treetop rex].freeze
  MARKER = /
    ^[^\w\n]*(?:\w+:\s*)?(?:
      (?:this\s+)?(?:file|code)\s+(?:(?:is|was|has\s+been)\s+)?(?:auto(?:matically)?[-\s]?)?generated\b|
      this\s+(?:\w+\s+)?(?:is|was|has\s+been)\s+(?:an?\s+)?(?:auto(?:matically)?[-\s]?)?generated\b|
      (?:an?\s+)?auto(?:matically)?[-\s]?generated\b|(?-i:Generated)\s+(?:by|from)\b|
      (?:an?\s+)?generated\s+(?:file|code)\b|(?:please\s+)?do\s+not\s+(?:edit|modify)\b
    )|
    (?<![\w@])@generated\b|(?-i:DO\s+NOT\s+(?:EDIT|MODIFY))\b
  /ix
  SIGIL = /^#\s*typed:\s*\w/
  HEADER = 40

  def initialize(path)
    @path = path
  end

  def generated? = GRAMMARS.any? { File.file?(@path.sub(/\.rb\z/, ".#{it}")) } || header.any? { MARKER.match?(it) }

  def typed? = SIGIL.match?(header.join)

  private

  def header
    @_header ||= File.foreach(@path, encoding: Encoding::UTF_8).lazy.map(&:scrub).first(HEADER)
      .take_while { it.strip.empty? || it.lstrip.start_with?("#") }
  end
end
