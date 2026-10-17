# frozen_string_literal: true

class Assay::Agreement
  def initialize(bundle, work, source)
    @bundle = bundle
    @work = work
    @source = source
  end

  def to_h
    agreed = rows.count { |_, human, label| human == label }
    {
      "size" => sheet.size, "labelled" => rows.size, "agreed" => agreed, "agreement" => ratio(agreed, rows.size),
      "kappa" => kappa(agreed), "human" => score(1), "existing" => score(2),
      "disagreements" => rows.reject { |_, human, label| human == label }
    }
  end

  private

  def kappa(agreed)
    size = rows.size.to_f
    chance = Assay::Lexicon::LABELS.sum { |label| tally(1, label) * tally(2, label) } / (size**2)
    rows.empty? || chance == 1 ? 0.0 : (((agreed / size) - chance) / (1 - chance)).round(4)
  end

  def tally(column, label) = rows.count { it[column] == label }

  def score(column)
    score = Assay::Score.new(rows.map { [it.first, it[column]] }, flagged)
    score.to_h.slice("precision", "recall", "fp", "fn", "ambiguous_flagged").merge(score.errors)
  end

  def flagged = @_flagged ||= Assay::Lexicon.new(@bundle, @work, Assay::Session::NAMES, reveal: false).sweep["raw"]

  def rows = @_rows ||= sheet.compact.map { |name, human| [name, check(name, human), labels.fetch(name)] }

  def check(name, human)
    raise(Assay::Failure, "#{@source}: #{name} is not in eval/names.yml") unless labels.key?(name)
    return human if Assay::Lexicon::LABELS.include?(human)
    raise(Assay::Failure, "#{@source}: #{name} is labelled #{human.inspect}, not doer, thing or ambiguous")
  end

  def sheet = @_sheet ||= YAML.safe_load_file(@source) || {}

  def labels
    @_labels ||= YAML.safe_load_file(Assay::Session::NAMES).slice(*Assay::Lexicon::LABELS)
      .flat_map { |label, names| names.map { [it, label] } }.to_h
  end

  def ratio(part, whole) = whole.zero? ? 0.0 : (part.to_f / whole).round(4)
end
