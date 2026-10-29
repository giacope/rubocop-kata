# frozen_string_literal: true

require "prism"

class Assay::Verdict
  def initialize(item, offenses, texts)
    @item = item
    @offenses = offenses
    @texts = texts
  end

  def to_h
    faults = self.faults
    @item.slice("id", "gap", "cop", "expect", "known").merge(
      "passed" => faults.empty?, "found" => mine.size, "faults" => faults,
      "messages" => mine.map { it["message"] }.uniq.first(2)
    )
  end

  def faults = [*expectation, *worded, *survival]

  private

  def mine = @offenses.select { it["cop_name"] == @item["cop"] }

  def expectation
    case @item["expect"]
    when "offense" then mine.empty? ? ["expected an offense, found none"] : []
    when "clean" then mine.empty? ? [] : ["expected no offense, found #{mine.size}"]
    else []
    end
  end

  def worded
    @item.fetch("absent", []).select { |text| mine.any? { it["message"].include?(text) } }
      .map { "a message says #{it.inspect}" }
  end

  def survival
    return [] unless @item["correct"]
    return ["the corrected file is missing"] if @texts.empty?
    text = @texts.first
    [*lost(text), *shape(text), *broken(text)]
  end

  def broken(text)
    broke = Prism.parse(@item.fetch("source")).success? && !Prism.parse(text).success?
    broke ? ["the corrected file does not parse"] : []
  end

  def lost(text)
    lines = text.lines.map(&:chomp)
    @item.fetch("keeps", []).reject { lines.include?(it) }.map { "correction removed #{it.inspect}" }
  end

  def shape(text)
    expected = @item["becomes"]
    expected && expected != text ? ["correction produced #{text.inspect}"] : []
  end
end
