# frozen_string_literal: true

require "zlib"

module RuboCop::Kata::Dictionary
  DATA = File.expand_path("../../../data", __dir__)
  WORDS = File.join(DATA, "words.txt.gz")
  SOFTWARE = File.join(DATA, "software.txt.gz")
  EXTRA = File.join(DATA, "supplement.txt")
  ENGLISH = Set.new(Zlib.gunzip(File.binread(WORDS)).split("\n")).freeze
  ENTRIES = (ENGLISH | Zlib.gunzip(File.binread(SOFTWARE)).split("\n") | File.readlines(EXTRA, chomp: true)).freeze
  AGENTS, THINGS, WORDNET_VERBS =
    %w[agents things verbs].map { Set.new(Zlib.gunzip(File.binread("#{DATA}/#{it}.txt.gz")).split("\n")).freeze }
  VERBS = (WORDNET_VERBS | File.readlines(File.join(DATA, "actions.txt"), chomp: true)).freeze
  CLIPPINGS = File.readlines(File.join(DATA, "clippings.txt"), chomp: true).to_h { it.split(" ", 2) }.freeze
  CORE = Set.new(File.readlines(File.join(DATA, "core.txt"), chomp: true)).freeze
end
