# frozen_string_literal: true

class Assay::Comparison
  include Assay::Reporting

  NAMES = %w[precision recall fp fn ambiguous_flagged roles_flagged].freeze
  PARTS = {
    "cases" => %i[cases misses], "names" => %i[names errata], "settings" => %i[settings], "cli" => %i[console],
    "human" => %i[panel accord]
  }.freeze
  PANEL = { "human" => "the human's labels", "existing" => "eval/names.yml" }.freeze

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

  def misses = "## Still failing\n\n#{failures.map { miss(it) }.join("\n")}\n"

  def miss(row) = "- `#{row["id"]}`#{" (known)" if row["known"]}: #{row["faults"].join("; ")}"

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

  def panel
    section(
      "Raw doer rule on #{@after.dig("human", "labelled")} human-labelled names", ["Scored against", *NAMES.first(4)],
      PANEL.map { |key, title| [title, *NAMES.first(4).map { shift("human", key, it) }] }
    )
  end

  def accord
    human = @after.fetch("human")
    "Agreement with eval/names.yml: #{human["agreed"]} of #{human["labelled"]} (#{human["agreement"]}), " \
      "Cohen's kappa #{human["kappa"]}. Disagreements: " \
      "#{human["disagreements"].map { |name, mine, theirs| "#{name} (#{mine}, was #{theirs})" }.join(", ")}.\n"
  end

  def console = section("CLI", %w[Case Result], @after.dig("cli", "results").map { [it["id"], outcome(it)] })

  def outcome(row)
    [@before.dig("cli", "results")&.find { it["id"] == row["id"] }, row].compact
      .map { it["passed"] ? "pass" : "fail" }.join(" → ")
  end
end
