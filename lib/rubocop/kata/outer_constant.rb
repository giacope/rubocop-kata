# frozen_string_literal: true

module RuboCop::Kata::OuterConstant
  def on_casgn(node)
    super unless node.namespace.nil? && node.each_ancestor(:class, :module, :sclass).any?
  end
end

RuboCop::Cop::Lint::SelfAssignment.prepend(RuboCop::Kata::OuterConstant)
