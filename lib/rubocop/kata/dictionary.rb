# frozen_string_literal: true

require "zlib"

class RuboCop::Kata::Dictionary
  DATA = File.expand_path("../../../data", __dir__)
  WORDS = File.join(DATA, "words.txt.gz")
  SOFTWARE = File.join(DATA, "software.txt.gz")
  EXTRA = File.join(DATA, "supplement.txt")
  ENGLISH = Set.new(Zlib.gunzip(File.binread(WORDS)).split("\n")).freeze
  ENTRIES = (ENGLISH | Zlib.gunzip(File.binread(SOFTWARE)).split("\n") | File.readlines(EXTRA, chomp: true)).freeze
  CLIPPINGS = File.readlines(File.join(DATA, "clippings.txt"), chomp: true).to_h { it.split(" ", 2) }.freeze
  private_constant :DATA, :WORDS, :SOFTWARE, :EXTRA, :ENGLISH, :ENTRIES, :CLIPPINGS

  def initialize(english = ENGLISH, entries = ENTRIES, clippings = CLIPPINGS)
    @english = english
    @entries = entries
    @clippings = clippings
  end

  def english?(word) = @english.include?(word)

  def entry?(word) = @entries.include?(word)

  def clipping?(word) = @clippings.key?(word)

  def expansions(words) = words.filter_map { @clippings[it] }
end
