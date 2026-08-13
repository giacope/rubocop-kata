# frozen_string_literal: true

class RuboCop::Cop::Kata::NoNilReturn < RuboCop::Cop::Base
  MSG = "Returning nil hands the caller a bomb; raise or return a real object."

  def on_return(node)
    add_offense(node, message: MSG) if node.children.first&.nil_type?
  end

  def on_def(node)
    last = tail(node.body)
    add_offense(last, message: MSG) if last&.nil_type?
  end
  alias on_defs on_def

  private

  def tail(body) = body&.begin_type? ? body.children.last : body
end
