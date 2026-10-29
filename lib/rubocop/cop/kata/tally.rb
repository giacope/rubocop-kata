# frozen_string_literal: true

module RuboCop::Cop::Kata::Tally
  private

  def tally(labels) = joined(labels.map(&:to_s).tally.map { |label, count| counted(label, count) })

  def counted(label, count) = count > 1 ? "`#{label}` ×#{count}" : "`#{label}`"

  def joined(items) = items.size > 1 ? "#{items[0..-2].join(", ")} and #{items.last}" : items.join
end
