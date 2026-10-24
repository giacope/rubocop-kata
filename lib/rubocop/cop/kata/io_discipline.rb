# frozen_string_literal: true

class RuboCop::Cop::Kata::IoDiscipline < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::BootLayer

  MSG = "Write through the injected `%s`, not bare `%s`."
  SEAM_MSG = "Inject the stream `%s` writes to (`def initialize(io: %s)`) and write through it."
  STREAMS = %i[@io @out @output @stdout @stderr @stream @err @error].freeze

  RESTRICT_ON_SEND = %i[puts warn pp p].freeze

  def_node_matcher :bare_output?, "(send nil? ${:puts :warn :pp :p} ...)"

  def on_send(node)
    bare_output?(node) do |method|
      add_offense(node, message: message(node, method)) unless element?(node) || seam?(node)
    end
  end

  private

  def message(node, method)
    held = stream(node)
    return format(MSG, held, method) if held
    format(SEAM_MSG, method, method == :warn ? "$stderr" : "$stdout")
  end

  def stream(node)
    scope = node.each_ancestor(:class, :module).first
    scope ? scope.each_descendant(:ivasgn).map { it.children.first }.find { STREAMS.include?(it) } : nil
  end

  def element?(node) = node.method?(:p) && (!node.arguments? || !node.block_node.nil?)
end
