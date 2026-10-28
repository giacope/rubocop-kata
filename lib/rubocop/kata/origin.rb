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

  def initialize(path, header)
    @path = path
    @header = header
  end

  def generated? = GRAMMARS.any? { File.file?(@path.sub(/\.rb\z/, ".#{it}")) } || @header.any? { MARKER.match?(it) }
end
