# frozen_string_literal: true

class RuboCop::Cop::Kata::NoBooleanFlag < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster

  MSG = "A boolean flag is two methods trapped in one; split them or name the argument."
  DEFAULT_MSG = "`%s` defaults to a boolean flag, two methods trapped in one; split them or make it a keyword."
  PLACEHOLDER = /\?|(?<!:):\w/
  DISPATCH = %i[send public_send __send__].freeze

  def_node_matcher :expected?, "(send (send nil? :receive ...) :with ...)"

  def on_send(node)
    return if node.operator_method? || node.assignment_method? || allowed?(node.method_name) || expected?(node)
    node.arguments.each_with_index do |argument, index|
      add_offense(argument, message: MSG) if flag?(node, argument, index)
    end
  end

  def on_def(node)
    return if allowed?(node.method_name)
    node.arguments.each { flag(it) }
  end

  alias on_defs on_def

  private

  def flag?(node, argument, index)
    return false unless argument.boolean_type?
    before = node.arguments.first(index)
    before.none? { bound?(it) } && !(before.first&.sym_type? && !DISPATCH.include?(node.method_name))
  end

  def bound?(argument) = argument.type?(:str, :dstr) && PLACEHOLDER.match?(argument.source)

  def flag(argument)
    return unless argument.optarg_type? && argument.default_value.boolean_type?
    add_offense(argument, message: format(DEFAULT_MSG, argument.name))
  end

  def allowed?(name) = listed?("AllowedMethods", name.to_s)
end
