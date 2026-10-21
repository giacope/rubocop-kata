# frozen_string_literal: true

class Assay::Repair
  FAILURE = /error occurred|infinite loop/i
  REPORT = "fix.json"

  def initialize(corpus, dir, flag)
    @corpus = corpus
    @dir = dir
    @flag = flag
  end

  def to_h
    before = census.to_h
    outcome = @corpus.bundle.rubocop(
      @flag, "--format", "json", "--out", REPORT, "--cache", "false", *@corpus.paths, dir: @dir
    )
    tally.merge(
      "comments_before" => before, "comments_after" => census.to_h, "unparsable" => census.broken,
      "failures" => failures(outcome), "test" => @corpus.test(@dir)
    ).compact
  end

  private

  def failures(outcome) = outcome.stderr.lines.grep(FAILURE).map(&:strip).uniq.first(20)

  def census = Assay::Census.new(@dir, @corpus.paths)

  def tally
    cops = fixed
    { "corrected" => cops.size, "corrected_cops" => cops.uniq.sort }
  end

  def fixed
    path = File.join(@dir, REPORT)
    return [] unless File.file?(path)
    JSON.parse(File.read(path)).fetch("files").flat_map { |file| file["offenses"].select { it["corrected"] } }
      .map { it["cop_name"] }
  end
end
