# frozen_string_literal: true

module RuboCop::Cop::Kata::BootLayer
  OBJECTS = %i[class module sclass def defs].freeze
  HOOKS = %i[initializer after_initialize before_initialize before_configuration to_prepare on_load].freeze

  private

  def seam?(node) = node.each_ancestor(:optarg, :kwoptarg).any? || node.each_ancestor(*OBJECTS).none? || hook?(node)

  def hook?(node) = node.each_ancestor(:block).any? { HOOKS.include?(it.method_name) }
end
