# frozen_string_literal: true

class Assay::Verdict
  def initialize(item, offenses, text)
    @item = item
    @offenses = offenses
    @text = text
  end

  def to_h
    faults = self.faults
    @item.slice("id", "gap", "cop", "expect", "known").merge(
      "passed" => faults.empty?, "found" => mine.size, "faults" => faults,
      "messages" => mine.map { it["message"] }.uniq.first(2)
    )
  end

  def faults = [expectation, *survival].compact

  private

  def mine = @offenses.select { it["cop_name"] == @item["cop"] }

  def expectation
    case @item["expect"]
    when "offense" then "expected an offense, found none" if mine.empty?
    when "clean" then "expected no offense, found #{mine.size}" unless mine.empty?
    end
  end

  def survival
    return [] unless @item["correct"]
    return ["the corrected file is missing"] if @text.nil?
    [*lost, *shape]
  end

  def lost
    lines = @text.lines.map(&:chomp)
    @item.fetch("keeps", []).reject { lines.include?(it) }.map { "correction removed #{it.inspect}" }
  end

  def shape
    expected = @item["becomes"]
    "correction produced #{@text.inspect}" if expected && expected != @text
  end
end
