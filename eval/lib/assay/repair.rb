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
    {
      "corrected" => corrected, "comments_before" => before, "comments_after" => census.to_h,
      "unparsable" => census.broken, "failures" => outcome.stderr.lines.grep(FAILURE).map(&:strip).uniq.first(20),
      "test" => @corpus.test(@dir)
    }.compact
  end

  private

  def census = Assay::Census.new(@dir, @corpus.paths)

  def corrected
    path = File.join(@dir, REPORT)
    return 0 unless File.file?(path)
    JSON.parse(File.read(path)).fetch("files").sum { |file| file["offenses"].count { it["corrected"] } }
  end
end
