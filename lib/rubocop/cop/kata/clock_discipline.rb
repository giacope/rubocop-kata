# frozen_string_literal: true

class RuboCop::Cop::Kata::ClockDiscipline < RuboCop::Cop::Base
  MSG = "Inject a clock; `%s.%s` reads the ambient time."

  RESTRICT_ON_SEND = %i[now today current].freeze

  def_node_matcher :bare_clock?, "(send $(const {nil? cbase} {:Time :Date :DateTime}) ${:now :today :current})"

  def on_send(node)
    bare_clock?(node) do |const, method|
      add_offense(node, message: format(MSG, const.const_name, method))
    end
  end
end
