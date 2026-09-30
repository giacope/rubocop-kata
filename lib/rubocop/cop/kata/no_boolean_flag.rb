# frozen_string_literal: true

class RuboCop::Cop::Kata::NoBooleanFlag < RuboCop::Cop::Base
  MSG = "A boolean flag is two methods trapped in one; split them or name the argument."
  DEFAULT_MSG = "`%s` defaults to a boolean flag, two methods trapped in one; split them or make it a keyword."

  def on_send(node)
    return if node.operator_method? || node.assignment_method? || allowed?(node.method_name)
    node.arguments.each { add_offense(it, message: MSG) if it.boolean_type? }
  end

  def on_def(node)
    return if allowed?(node.method_name)
    node.arguments.each { flag(it) }
  end

  alias on_defs on_def

  private

  def flag(argument)
    return unless argument.optarg_type? && argument.default_value.boolean_type?
    add_offense(argument, message: format(DEFAULT_MSG, argument.name))
  end

  def allowed?(name) = Array(cop_config["AllowedMethods"]).map(&:to_s).include?(name.to_s)
end
