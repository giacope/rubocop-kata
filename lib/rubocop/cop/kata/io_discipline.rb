# frozen_string_literal: true

class RuboCop::Cop::Kata::IoDiscipline < RuboCop::Cop::Base
  MSG = "Write through the injected `@io`, not bare `%s`."

  RESTRICT_ON_SEND = %i[puts warn pp p].freeze

  def_node_matcher :bare_output?, "(send nil? ${:puts :warn :pp :p} ...)"

  def on_send(node)
    bare_output?(node) do |method|
      add_offense(node, message: format(MSG, method)) unless element?(node)
    end
  end

  private

  def element?(node) = node.method?(:p) && (!node.arguments? || !node.block_node.nil?)
end
