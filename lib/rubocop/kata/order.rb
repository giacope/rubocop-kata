# frozen_string_literal: true

module RuboCop::Kata::Order
  private

  def precedes?(earlier, later) = (later.source_range.begin_pos <=> earlier.source_range.end_pos).positive?
end
