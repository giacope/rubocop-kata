# frozen_string_literal: true

class Assay::Board
  def initialize(data)
    @data = data
  end

  def markdown
    [header, cases, names, settings, console, corpora].compact.join("\n")
  end

  private

  def header
    kata = @data.fetch("kata")
    versions = kata.fetch("versions").map { |gem, version| "#{gem} #{version}" }.join(", ")
    "# Scoreboard: #{kata.fetch("commit")[0, 12]}#{" (dirty)" if kata["dirty"]}\n\n#{versions}\n"
  end

  def cases
    section = @data["cases"] or return
    rows = section.fetch("by_gap").map { |gap, row| [gap, row["passed"], row["total"]] }
    misses = section.fetch("results").reject { it["passed"] }.map { "- `#{it["id"]}` (#{it["cop"]}): #{it["faults"].join("; ")}" }
    ["## Snippet cases: #{section["passed"]}/#{section["total"]}\n", table(%w[Gap Passed Total], rows), *misses, ""]
      .join("\n")
  end

  def names
    section = @data["names"] or return
    rows = %w[raw shipped].product(%w[dev holdout all]).map { |variant, split| name_row(section, variant, split) }
    heads = ["Variant", "Split", "Precision", "Recall", "F1", "FP", "FN", "Ambiguous flagged", "Roles flagged"]
    ["## -er/-or/-ar names (#{section["size"]} labels)\n", table(heads, rows), *name_errors(section), ""].join("\n")
  end

  def name_row(section, variant, split)
    row = section.dig(variant, split)
    [
      variant, split, row["precision"], row["recall"], row["f1"], row["fp"], row["fn"],
      "#{row["ambiguous_flagged"]}/#{row["ambiguous"]}", "#{row["roles_flagged"]}/#{row["roles"]}"
    ]
  end

  def name_errors(section)
    row = section.dig("raw", "dev")
    ["", "Raw rule, dev split. False positives: #{row["false_positives"].join(", ")}.",
     "False negatives: #{row["false_negatives"].join(", ")}."]
  end

  def settings
    section = @data["settings"] or return
    rows = section.except("layout_silenced").map { |key, value| [key, value.is_a?(Array) ? value.join(", ") : value] }
    ["## Shipped configuration\n", table(%w[Fact Value], rows), "", "Layout cops silenced: #{section["layout_silenced"].join(", ")}", ""]
      .join("\n")
  end

  def console
    section = @data["cli"] or return
    rows = section.fetch("results").map { [it["id"], it["passed"] ? "pass" : "FAIL", it["faults"].join("; ")] }
    ["## CLI: #{section["passed"]}/#{section["total"]}\n", table(%w[Case Result Faults], rows), ""].join("\n")
  end

  def corpora
    section = @data["corpora"] or return
    ["## Corpora\n", table(%w[Corpus Files Lines Offenses PerKLOC], section.map { |name, row| corpus_row(name, row) }), "",
     safety(section), "", lengths(section), "", *section.map { |name, row| density(name, row) }].join("\n")
  end

  def corpus_row(name, row)
    [name, row["files"], row["lines"], row["offenses"], (row["offenses"] * 1000.0 / row["lines"]).round(1)]
  end

  def safety(section)
    heads = ["Corpus", "Mode", "Corrected", "Unparsable", "Comments kept", "YARD kept", "Encoding kept", "Tests"]
    rows = section.flat_map { |name, row| %w[safe all].filter_map { fix_row(name, it, row[it]) } }
    "### Autocorrect safety\n\n#{table(heads, rows)}"
  end

  def fix_row(name, mode, row)
    return unless row
    before = row["comments_before"]
    after = row["comments_after"]
    [
      name, mode == "safe" ? "-a" : "-A", row["corrected"], row["unparsable"].size,
      kept(before["comments"], after["comments"]), kept(before.dig("kinds", "yard"), after.dig("kinds", "yard")),
      kept(before.dig("kinds", "encoding"), after.dig("kinds", "encoding")), verdict(row["test"])
    ]
  end

  def kept(before, after) = "#{after.to_i}/#{before.to_i}"

  def verdict(test)
    return "n/a" unless test
    "#{test["examples"]} examples, #{test["failures"]} failures (exit #{test["status"]})"
  end

  def lengths(section)
    rows = section.map { |name, row| [name, *row["method_length"].values_at("kata", "without_method_call", "raw")] }
    "### Metrics/MethodLength offenses by CountAsOne\n\n#{table(%w[Corpus kata without_method_call none], rows)}"
  end

  def density(name, row)
    top = row["per_kloc"].first(15).map { |cop, value| [cop, row["counts"][cop], value] }
    "### #{name}: top cops per kLOC\n\n#{table(%w[Cop Offenses PerKLOC], top)}\n"
  end

  def table(heads, rows)
    lines = [heads, heads.map { "---" }, *rows].map { |cells| "| #{cells.join(" | ")} |" }
    lines.join("\n")
  end
end
