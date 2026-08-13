# frozen_string_literal: true

class RuboCop::Cop::Kata::ConstructorDiscipline < RuboCop::Cop::Base
  MSG = "A constructor assigns; it does not compute. Move `%s` out of `initialize`."

  ALLOWED = %i[raise freeze].freeze

  def on_def(node)
    return unless node.method?(:initialize)
    node.each_descendant(:send) do |send|
      next if ALLOWED.include?(send.method_name)
      add_offense(send, message: format(MSG, send.method_name))
    end
  end
end
