# frozen_string_literal: true

class RuboCop::Cop::Kata::ClockDiscipline < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::BootLayer
  include RuboCop::Cop::Kata::Ownership

  MSG = "Inject a clock; `%s` reads the ambient time."
  RANDOM_MSG = "Inject a source of randomness; `%s` draws from the ambient one."
  DRAW_MSG = "Pass `%s` an injected generator (`random: @random`); without one it draws from the ambient source."

  def_node_matcher :ambient?, <<~PATTERN
    {
      (send (const {nil? cbase} {:Time :Date :DateTime}) {:now :today :current :yesterday :tomorrow})
      (send (send (const {nil? cbase} :Time) :zone) {:now :today})
      (send (const {nil? cbase} :Time) :new)
      (send (const {nil? cbase} :Process) :clock_gettime ...)
    }
  PATTERN

  def_node_matcher :random?, <<~PATTERN
    {
      (send (const {nil? cbase} :SecureRandom) _ ...)
      (send (const {nil? cbase} :Random) {:rand :bytes :random_number :new_seed :urandom :seed} ...)
      (send (const {nil? cbase} :Random) :new)
      (send (const {nil? cbase} :Kernel) :rand ...)
    }
  PATTERN

  def_node_matcher :kernel?, "(send nil? $:rand ...)"

  def_node_matcher :draw?, "(send $!nil? ${:sample :shuffle :shuffle!} ...)"

  def on_send(node)
    return if seam?(node)
    return add_offense(node, message: format(MSG, node.source)) if ambient?(node)
    return add_offense(node, message: format(RANDOM_MSG, spelled(node))) if random?(node) || bare?(node)
    draw?(node) { |held, name| add_offense(node, message: format(DRAW_MSG, name)) unless seeded?(node) || owner?(held) }
  end

  private

  def spelled(node) = [node.receiver&.source, node.method_name].compact.join(".")

  def bare?(node) = kernel?(node) { !own?(it) }

  def owner?(held) = held.const_type? && owned?(held)

  def seeded?(node) = node.arguments.any? { it.hash_type? && it.keys.any? { |key| key.value == :random } }
end
