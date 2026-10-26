# frozen_string_literal: true

require "rubocop-elegant"

module RuboCop::Kata::ForeignText
  private

  def heredocs
    tree = processed_source.ast
    texts = tree ? tree.each_node(:xstr).reject(&:heredoc?).flat_map { ((it.first_line + 1)..it.last_line).to_a } : []
    super | texts
  end
end

if defined?(RuboCop::Cop::Elegant::MonotonicIndents)
  RuboCop::Cop::Elegant::MonotonicIndents.prepend(RuboCop::Kata::ForeignText)
end
