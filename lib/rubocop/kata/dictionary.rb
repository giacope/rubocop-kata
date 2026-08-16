# frozen_string_literal: true

require "zlib"

module RuboCop::Kata::Dictionary
  WORDS = File.expand_path("../../../data/words.txt.gz", __dir__)
  SOFTWARE = File.expand_path("../../../data/software.txt.gz", __dir__)
  EXTRA = File.expand_path("../../../data/supplement.txt", __dir__)
  ENTRIES = Set.new(
    [WORDS, SOFTWARE].flat_map { Zlib.gunzip(File.binread(it)).split("\n") } +
      File.readlines(EXTRA, chomp: true)
  ).freeze
end
