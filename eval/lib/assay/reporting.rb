# frozen_string_literal: true

module Assay::Reporting
  def initialize(before, after)
    @before = before || {}
    @after = after
  end

  private

  def shift(*path)
    old = @before.dig(*path)
    now = @after.dig(*path)
    old.nil? || old == now ? now.to_s : "#{old.inspect} → #{now.inspect}"
  end

  def section(title, heads, rows) = "## #{title}\n\n#{Assay::Table.new(heads, rows)}\n"
end
