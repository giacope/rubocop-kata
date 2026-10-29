# frozen_string_literal: true

class RuboCop::Kata::Lexicon
  BRANDS = { "RuboCop" => "Rubocop", "RSpec" => "Rspec" }.freeze
  SPELLED = { "RuboCop" => "rubocop", "RSpec" => "rspec" }.freeze
  WORD = /\A[a-z][a-z0-9]+\z/

  def initialize(codebase, manifest, dictionary = RuboCop::Kata::Dictionary.new)
    @codebase = codebase
    @manifest = manifest
    @dictionary = dictionary
  end

  def to_h
    words = (@codebase.names + coined).uniq.reject { plain?(it) }
    layer = words.empty? ? {} : { "Kata/RealWords" => { "Vocabulary" => words } }
    layer = layer.merge(transforms)
    return layer unless @manifest.parser?
    spoken = layer.fetch("Kata/RealWords", {}).merge("NodeCallbacks" => true)
    layer.merge("Kata/RealWords" => spoken, "Lint/BooleanSymbol" => { "Enabled" => false })
  end

  private

  def coined
    gems = @manifest.dependencies.flat_map { it.downcase.split(/[-_.]/) }
    nodes = @manifest.parser? ? Parser::Meta::NODE_TYPES.map(&:to_s) : []
    [*gems, *@codebase.constants.flat_map { spelled(it).split("_") }, *nodes].grep(WORD).reject { clipping?(it) }
  end

  def spelled(name) = snake(BRANDS.reduce(name) { |text, (brand, word)| text.gsub(brand, word) })

  def transforms
    found =
      (@codebase.constants - SPELLED.keys).filter_map do |name|
        path = spelled(name)
        [name, path] unless path == snake(name)
      end
    found.empty? ? {} : { "RSpec/SpecFilePathFormat" => { "CustomTransform" => SPELLED.merge(found.to_h) } }
  end

  def snake(name) = name.gsub(/([^A-Z])([A-Z]+)/, '\1_\2').gsub(/([A-Z])([A-Z][^A-Z\d]+)/, '\1_\2').downcase

  def plain?(word) = @dictionary.entry?(word) && !clipping?(word)

  def clipping?(word) = @dictionary.clipping?(word)
end
