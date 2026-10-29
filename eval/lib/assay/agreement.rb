# frozen_string_literal: true

class Assay::Agreement
  LABELS = %w[doer thing ambiguous].freeze
  NAMES = File.expand_path("../../names.yml", __dir__)

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
    chance = LABELS.sum { |label| tally(1, label) * tally(2, label) } / (size**2)
    rows.empty? || chance == 1 ? 0.0 : (((agreed / size) - chance) / (1 - chance)).round(4)
  end

  def tally(column, label) = rows.count { it[column] == label }

  def score(column)
    score = Assay::Score.new(rows.map { [it.first, it[column]] }, flagged)
    score.to_h.slice("precision", "recall", "fp", "fn", "ambiguous_flagged").merge(score.errors)
  end

  def flagged = @_flagged ||= lexicon.sweep.fetch("raw", [])

  def rows = @_rows ||= sheet.compact.map { |name, human| [name, check(name, human), labels.fetch(name)] }

  def check(name, human)
    raise(Assay::Failure, "#{@source}: #{name} is not in eval/names.yml") unless labels.key?(name)
    return human if LABELS.include?(human)
    raise(Assay::Failure, "#{@source}: #{name} is labelled #{human.inspect}, not doer, thing or ambiguous")
  end

  def sheet = @_sheet ||= YAML.safe_load_file(@source) || {}

  def labels = @_labels ||= lexicon.labelled

  def lexicon = Assay::Lexicon.new(@bundle, @work, NAMES, reveal: false)

  def ratio(part, whole) = whole.zero? ? 0.0 : (part.to_f / whole).round(4)
end
