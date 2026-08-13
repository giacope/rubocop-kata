# frozen_string_literal: true

class RuboCop::Cop::Kata::NoUtilName < RuboCop::Cop::Base
  MSG = "`%s` is a junk drawer; it hides the concept the code is missing."

  def on_class(node) = check(node)

  def on_module(node) = check(node)

  private

  def check(node)
    name = node.identifier.short_name.to_s
    return unless banned?(name)
    add_offense(node.identifier, message: format(MSG, name))
  end

  def banned?(name) = Array(cop_config["BannedNames"]).map(&:to_s).include?(name)
end
