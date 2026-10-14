# frozen_string_literal: true

class Assay::Score
  def initialize(group, flagged)
    @group = group
    @flagged = flagged
  end

  def to_h
    {
      "tp" => caught, "fp" => wrong, "fn" => missed, "precision" => precision, "recall" => recall, "f1" => harmonic,
      "ambiguous_flagged" => hits("ambiguous"), "ambiguous" => total("ambiguous"),
      "roles_flagged" => hits("roles"), "roles" => total("roles")
    }
  end

  def errors
    {
      "false_positives" => @group.select { |name, label| label == "thing" && @flagged.include?(name) }.map(&:first),
      "false_negatives" => @group.select { |name, label| label == "doer" && !@flagged.include?(name) }.map(&:first)
    }
  end

  private

  def caught = hits("doer")

  def wrong = hits("thing")

  def missed = total("doer") - caught

  def precision = ratio(caught, caught + wrong)

  def recall = ratio(caught, caught + missed)

  def harmonic = ratio(2 * precision * recall, precision + recall)

  def hits(label) = @group.count { |name, kind| kind == label && @flagged.include?(name) }

  def total(label) = @group.count { it.last == label }

  def ratio(part, whole) = whole.zero? ? 0.0 : (part.to_f / whole).round(4)
end
