# frozen_string_literal: true

module RuboCop::Kata::ForeignSetting
  def on_send(node)
    receiver = node.receiver
    super if receiver.nil? || receiver.self_type?
  end
end

RuboCop::Cop::Style::ClassVars.prepend(RuboCop::Kata::ForeignSetting)
