# frozen_string_literal: true

module RuboCop::Cop::Kata::BootLayer
  OBJECTS = %i[class module sclass def defs].freeze

  private

  def seam?(node) = node.each_ancestor(:optarg, :kwoptarg).any? || node.each_ancestor(*OBJECTS).none?
end
