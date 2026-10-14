# frozen_string_literal: true

class Lexicography::Wordnet
  NOUN = /\A[a-z]+(?:er|or|ar)\z/
  WORD = /\A[a-z]+\z/

  def initialize(directory)
    @directory = directory
  end

  def write(target)
    agents = nouns.select { agent?(it) }
    dump(File.join(target, "agents.txt.gz"), agents)
    dump(File.join(target, "things.txt.gz"), nouns - agents)
    dump(File.join(target, "verbs.txt.gz"), verbs.to_a.grep(WORD))
  end

  private

  def agent?(word)
    candidates = RuboCop::Kata::Agency.new(word).stems.select { verbs.include?(it) }
    first, second = senses(word)
    return false if candidates.empty?
    agent(first, word, candidates) || (first.person? && !second.nil? && agent(second, word, candidates))
  end

  def agent(sense, word, candidates)
    return false unless sense.lexical?
    candidates.intersect?(linked(sense, word)) || candidates.any? { sense.glossed?(it) }
  end

  def linked(sense, word)
    sense.derived(word).map { |offset, slot| Lexicography::Synset.new(verbal.fetch(offset)).words[slot] }
  end

  def senses(word) = index("noun").fetch(word).map { Lexicography::Synset.new(nominal.fetch(it)) }

  def nouns = @_nouns ||= index("noun").keys.grep(NOUN).sort

  def verbs = @_verbs ||= Set.new(index("verb").keys)

  def index(part)
    @_index ||= {}
    @_index[part] ||= lines("index.#{part}").to_h { entry(it) }
  end

  def entry(line)
    fields = line.split
    [fields[0], fields[(6 + fields[3].to_i)..].first(fields[2].to_i)]
  end

  def nominal = @_nominal ||= data("noun")

  def verbal = @_verbal ||= data("verb")

  def data(part) = lines("data.#{part}").to_h { [it[0, 8], it] }

  def lines(name) = File.foreach(File.join(@directory, name)).reject { it.start_with?(" ") }

  def dump(path, words)
    Zlib::GzipWriter.open(path) do |gzip|
      gzip.mtime = 1
      gzip.write(words.sort.uniq.join("\n"))
    end
  end
end
