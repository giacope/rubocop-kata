# frozen_string_literal: true

class RuboCop::Cop::Kata::NoBooleanFlag < RuboCop::Cop::Base
  MSG = "A boolean flag is two methods trapped in one; split them or name the argument."

  def on_send(node)
    return if node.operator_method? || node.assignment_method?
    node.arguments.each { add_offense(it, message: MSG) if it.boolean_type? }
  end
end
