# frozen_string_literal: true

class RuboCop::Cop::Kata::NoClassMethodLogic < RuboCop::Cop::Base
  MSG = "`%s` puts logic on the class; classes construct, instances work."

  def on_defs(node)
    name = node.method_name.to_s
    return if constructor?(name)
    add_offense(node.loc.name, message: format(MSG, name))
  end

  private

  def constructor?(name) = name.start_with?("from_") || allowed?(name)

  def allowed?(name) = Array(cop_config["AllowedNames"]).map(&:to_s).include?(name)
end
