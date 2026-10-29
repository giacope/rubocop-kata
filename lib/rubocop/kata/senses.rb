# frozen_string_literal: true

require "zlib"

class RuboCop::Kata::Senses
  DATA = File.expand_path("../../../data", __dir__)
  AGENTS, THINGS, WORDNET_VERBS =
    %w[agents things verbs].map { Set.new(Zlib.gunzip(File.binread("#{DATA}/#{it}.txt.gz")).split("\n")).freeze }
  VERBS = (WORDNET_VERBS | File.readlines(File.join(DATA, "actions.txt"), chomp: true)).freeze
  private_constant :DATA, :AGENTS, :THINGS, :WORDNET_VERBS, :VERBS

  def initialize(agents = AGENTS, things = THINGS, verbs = VERBS)
    @agents = agents
    @things = things
    @verbs = verbs
  end

  def agent?(word) = @agents.include?(word)

  def thing?(word) = @things.include?(word)

  def verb?(word) = @verbs.include?(word)
end
