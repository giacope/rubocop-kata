# frozen_string_literal: true

class Assay::Comparison
  include Assay::Reporting

  NAMES = %w[precision recall fp fn ambiguous_flagged roles_flagged].freeze
  PARTS = {
    "cases" => %i[cases misses], "names" => %i[names errata], "settings" => %i[settings], "cli" => %i[console]
  }.freeze

  def markdown
    parts = PARTS.select { |key, _| @after.key?(key) }.values.flatten.map { method(it).call }
    survey = @after.key?("corpora") ? Assay::Survey.new(@before, @after).to_a : []
    [header, *parts, *survey].join("\n")
  end

  private

  def header
    kata = @after.fetch("kata")
    "# Scoreboard: #{kata.fetch("commit")[0, 12]}#{" (dirty)" if kata["dirty"]}\n\n" \
      "#{kata.fetch("versions").map { |gem, version| "#{gem} #{version}" }.join(", ")}\n"
  end

  def cases
    section(
      "Snippet cases (shipped defaults)", %w[Gap Passed],
      [*@after.dig("cases", "by_gap").keys.map { [it, passed("cases", "by_gap", it)] }, ["all", passed("cases")]]
    )
  end

  def passed(*path)
    old = @before.dig(*path)
    now = @after.dig(*path)
    "#{"#{old["passed"]} → " if old}#{now["passed"]} of #{now["total"]}"
  end

  def misses
    "## Still failing\n\n#{failures.map { "- `#{it["id"]}`: #{it["faults"].join("; ")}" }.join("\n")}\n"
  end

  def failures = %w[cases cli].flat_map { @after.dig(it, "results").to_a }.reject { it["passed"] }

  def names
    section(
      "-er/-or/-ar names (#{@after.dig("names", "size")} labels)", ["Variant", "Split", *NAMES],
      %w[raw shipped].product(%w[dev holdout all]).map { |key| [*key, *NAMES.map { shift("names", *key, it) }] }
    )
  end

  def errata
    row = @after.dig("names", "raw", "dev")
    "Raw rule on the dev split. False positives: #{row["false_positives"].join(", ")}. " \
      "False negatives: #{row["false_negatives"].join(", ")}.\n"
  end

  def settings
    section(
      "Shipped configuration", %w[Fact Value],
      (@after.fetch("settings").keys - %w[layout_silenced]).map { [it, shift("settings", it)] }
    )
  end

  def console = section("CLI", %w[Case Result], @after.dig("cli", "results").map { [it["id"], outcome(it)] })

  def outcome(row)
    [@before.dig("cli", "results")&.find { it["id"] == row["id"] }, row].compact
      .map { it["passed"] ? "pass" : "fail" }.join(" → ")
  end
end
