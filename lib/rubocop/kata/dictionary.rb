# frozen_string_literal: true

require "zlib"

module RuboCop::Kata::Dictionary
  DATA = File.expand_path("../../../data", __dir__)
  WORDS = File.join(DATA, "words.txt.gz")
  SOFTWARE = File.join(DATA, "software.txt.gz")
  EXTRA = File.join(DATA, "supplement.txt")
  ENTRIES = Set.new(
    [WORDS, SOFTWARE].flat_map { Zlib.gunzip(File.binread(it)).split("\n") } +
      File.readlines(EXTRA, chomp: true)
  ).freeze
  WORDNET = ->(name) { Set.new(Zlib.gunzip(File.binread(File.join(DATA, "#{name}.txt.gz"))).split("\n")).freeze }
  AGENTS = WORDNET.call("agents")
  THINGS = WORDNET.call("things")
  VERBS = WORDNET.call("verbs")
  CLIPPINGS = File.readlines(File.join(DATA, "clippings.txt"), chomp: true).to_h { it.split(" ", 2) }.freeze
end
