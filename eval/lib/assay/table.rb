# frozen_string_literal: true

class Assay::Table
  def initialize(heads, rows)
    @heads = heads
    @rows = rows
  end

  def to_s = [@heads, @heads.map { "---" }, *@rows].map { |cells| "| #{cells.join(" | ")} |" }.join("\n")
end
