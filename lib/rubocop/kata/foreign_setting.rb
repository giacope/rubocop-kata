# frozen_string_literal: true

# Style/ClassVars, narrowed to the project's own class variables: setting one
# on another class (`Minitest.class_variable_set(:@@installed_at_exit, …)`)
# configures that class, which reads it, and has no class instance variable
# to move to.
module RuboCop::Kata::ForeignSetting
  def on_send(node)
    receiver = node.receiver
    super if receiver.nil? || receiver.self_type?
  end
end

RuboCop::Cop::Style::ClassVars.prepend(RuboCop::Kata::ForeignSetting)
