# frozen_string_literal: true

class RuboCop::Cop::Kata::AgentNoun < RuboCop::Cop::Base
  MSG = "`%s` names a doer; name the class for the thing it is, not the work it does."

  SUFFIX = /(?:er|or)\z/

  def on_class(node) = check(node)

  def on_module(node) = check(node)

  private

  def check(node)
    name = node.identifier.short_name.to_s
    return unless SUFFIX.match?(name)
    return if allowed?(name)
    add_offense(node.identifier, message: format(MSG, name))
  end

  def allowed?(name) = Array(cop_config["AllowedNames"]).map(&:to_s).include?(name)
end
