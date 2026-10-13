# frozen_string_literal: true

class Assay::Comparison
  def initialize(before, after)
    @before = before
    @after = after
  end

  def markdown
    [cases, names, settings, console, corpora, safety, lengths, *movement, *drift].join("\n")
  end

  private

  def cases
    gaps = @after.dig("cases", "by_gap").keys | @before.dig("cases", "by_gap").keys
    rows = gaps.map { |gap| [gap, passed("cases", "by_gap", gap)] }
    rows << ["all", "#{@before.dig("cases", "passed")} → #{@after.dig("cases", "passed")} of #{@after.dig("cases", "total")}"]
    "## Snippet cases (shipped defaults)\n\n#{table(%w[Gap Passed], rows)}\n"
  end

  def passed(*path)
    old = @before.dig(*path) || { "passed" => 0 }
    new = @after.dig(*path)
    "#{old["passed"]} → #{new["passed"]} of #{new["total"]}"
  end

  def names
    rows = %w[raw shipped].product(%w[dev holdout all]).map do |variant, split|
      [variant, split, *%w[precision recall fp fn ambiguous_flagged roles_flagged].map { shift("names", variant, split, it) }]
    end
    heads = %w[Variant Split Precision Recall FP FN AmbiguousFlagged RolesFlagged]
    "## -er/-or/-ar names (#{@after.dig("names", "size")} labels)\n\n#{table(heads, rows)}\n"
  end

  def settings
    keys = @after.fetch("settings").keys - %w[layout_silenced]
    rows = keys.map { [it, shift("settings", it)] }
    "## Shipped configuration\n\n#{table(%w[Fact Change], rows)}\n"
  end

  def console
    rows = @after.dig("cli", "results").map do |row|
      old = @before.dig("cli", "results").find { it["id"] == row["id"] }
      [row["id"], "#{label(old)} → #{label(row)}"]
    end
    "## CLI\n\n#{table(%w[Case Result], rows)}\n"
  end

  def label(row) = row && row["passed"] ? "pass" : "fail"

  def corpora
    rows = @after.fetch("corpora").keys.map do |name|
      [name, shift("corpora", name, "offenses"), density(@before, name), density(@after, name)]
    end
    "## Corpora\n\n#{table(%w[Corpus Offenses PerKLOCBefore PerKLOCAfter], rows)}\n"
  end

  def density(data, name)
    row = data.dig("corpora", name)
    (row["offenses"] * 1000.0 / row["lines"]).round(1)
  end

  def safety
    rows = @after.fetch("corpora").flat_map do |name, row|
      %w[safe all].filter_map { |mode| fix(name, mode) if row[mode] }
    end
    heads = ["Corpus", "Mode", "Unparsable", "Comments kept", "YARD kept", "Encoding kept", "Tests (failures)"]
    "## Autocorrect safety\n\n#{table(heads, rows)}\n"
  end

  def fix(name, mode)
    old = @before.dig("corpora", name, mode)
    new = @after.dig("corpora", name, mode)
    [
      name, mode == "safe" ? "-a" : "-A", "#{old["unparsable"].size} → #{new["unparsable"].size}",
      *[nil, "yard", "encoding"].map { kept(old, new, it) }, "#{failures(old)} → #{failures(new)}"
    ]
  end

  def kept(old, new, kind) = "#{share(old, kind)} → #{share(new, kind)}"

  def share(row, kind)
    path = kind ? ["kinds", kind] : ["comments"]
    "#{row["comments_after"].dig(*path).to_i}/#{row["comments_before"].dig(*path).to_i}"
  end

  def failures(row) = row["test"] ? row.dig("test", "failures").inspect : "n/a"

  def lengths
    rows = @after.fetch("corpora").keys.map do |name|
      [name, *%w[kata without_method_call raw].map { shift("corpora", name, "method_length", it) }]
    end
    "## Metrics/MethodLength offenses by CountAsOne\n\n#{table(%w[Corpus kata without_method_call none], rows)}\n"
  end

  def movement
    @after.fetch("corpora").keys.map do |name|
      cops = (counts(@before, name).keys | counts(@after, name).keys).select { relevant?(name, it) }.sort
      rows = cops.map { |cop| [cop, *[@before, @after].map { kloc(it, name, cop) }, delta(name, cop)] }
      "## #{name}: offenses per kLOC by cop\n\n#{table(%w[Cop Before After Delta], rows)}\n"
    end
  end

  def relevant?(name, cop)
    cop.start_with?("Kata/") || [@before, @after].any? { kloc(it, name, cop) >= 1.0 } || delta(name, cop).abs >= 0.5
  end

  def counts(data, name) = data.dig("corpora", name, "counts") || {}

  def kloc(data, name, cop) = data.dig("corpora", name, "per_kloc", cop) || 0.0

  def delta(name, cop) = (kloc(@after, name, cop) - kloc(@before, name, cop)).round(2)

  def drift
    @after.fetch("corpora").filter_map do |name, row|
      next unless row["offense_list"]
      fresh = row["offense_list"].map { it.first(3) } - @before.dig("corpora", name, "offense_list").map { it.first(3) }
      gone = @before.dig("corpora", name, "offense_list").map { it.first(3) } - row["offense_list"].map { it.first(3) }
      "## #{name}: offenses this change adds and removes\n\n#{table(%w[Cop Added Removed], tally(fresh, gone))}\n"
    end
  end

  def tally(fresh, gone)
    added = fresh.map(&:last).tally
    removed = gone.map(&:last).tally
    (added.keys | removed.keys).sort.map { [it, added.fetch(it, 0), removed.fetch(it, 0)] }
  end

  def shift(*path)
    old = @before.dig(*path)
    new = @after.dig(*path)
    old == new ? new.to_s : "#{old.inspect} → #{new.inspect}"
  end

  def table(heads, rows)
    [heads, heads.map { "---" }, *rows].map { |cells| "| #{cells.join(" | ")} |" }.join("\n")
  end
end
