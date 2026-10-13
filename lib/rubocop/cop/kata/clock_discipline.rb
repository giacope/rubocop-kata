# frozen_string_literal: true

class RuboCop::Cop::Kata::ClockDiscipline < RuboCop::Cop::Base
  MSG = "Inject a clock; `%s` reads the ambient time."

  RESTRICT_ON_SEND = %i[now today current yesterday tomorrow new clock_gettime].freeze

  def_node_matcher :ambient?, <<~PATTERN
    {
      (send (const {nil? cbase} {:Time :Date :DateTime}) {:now :today :current :yesterday :tomorrow})
      (send (send (const {nil? cbase} :Time) :zone) {:now :today})
      (send (const {nil? cbase} :Time) :new)
      (send (const {nil? cbase} :Process) :clock_gettime ...)
    }
  PATTERN

  def on_send(node)
    add_offense(node, message: format(MSG, node.source)) if ambient?(node) && !seam?(node)
  end

  private

  def seam?(node) = node.each_ancestor(:optarg, :kwoptarg).any?
end
