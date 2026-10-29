# frozen_string_literal: true

class RuboCop::Kata::Agency
  SUFFIX = /(?:er|or)\z/
  ENDINGS = [
    [/er\z/, ""], [/r\z/, ""], [/or\z/, ""], [/or\z/, "e"], [/ier\z/, "y"], [/([b-df-hj-np-tv-z])\1er\z/, '\1'],
    [/ar\z/, ""], [/ar\z/, "e"], [/([b-df-hj-np-tv-z])\1ar\z/, '\1']
  ].freeze
  PREFIX = /\A(?:de|dis|mis|pre|re|un)(?=[a-z]{3})/
  VERBAL = /(?:ize|ise|ify|ate)\z/

  def initialize(word, senses = RuboCop::Kata::Senses.new)
    @word = word
    @senses = senses
  end

  def doer?
    return true if @senses.agent?(@word)
    return false if @senses.thing?(@word) || !suffixed?
    verbal?
  end

  def suffixed? = SUFFIX.match?(@word)

  def stems = ENDINGS.filter_map { |ending, stem| @word.sub(ending, stem) if ending.match?(@word) }.uniq

  private

  def verbal? = stems.any? { VERBAL.match?(it) || verb?(it) || verb?(it.sub(PREFIX, "")) }

  def verb?(stem) = @senses.verb?(stem)
end
