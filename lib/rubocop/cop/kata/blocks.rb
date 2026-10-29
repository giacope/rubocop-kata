# frozen_string_literal: true

module RuboCop::Cop::Kata::Blocks
  private

  def blocked(call)
    outer = call.parent
    outer&.any_block_type? && outer.send_node.equal?(call) ? outer : call
  end
end
