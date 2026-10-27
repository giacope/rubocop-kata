# frozen_string_literal: true

require "rubocop-elegant"

module RuboCop::Kata::ForeignText
  private

  def heredocs
    tree = processed_source.ast
    texts = tree ? tree.each_node(:str, :dstr, :xstr, :regexp).flat_map { verbatim(it) } : []
    super | texts
  end

  def verbatim(node)
    location = node.loc
    return [] unless node.multiline? && location.respond_to?(:begin) && location.begin
    first = node.first_line
    first += 1 unless processed_source.lines[first - 1][0...location.column].strip.empty?
    (first..node.last_line).to_a
  end
end

if defined?(RuboCop::Cop::Elegant::MonotonicIndents)
  RuboCop::Cop::Elegant::MonotonicIndents.prepend(RuboCop::Kata::ForeignText)
end
