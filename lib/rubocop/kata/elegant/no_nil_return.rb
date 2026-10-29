# frozen_string_literal: true

class RuboCop::Kata::Elegant::NoNilReturn < RuboCop::Cop::Elegant::NoNilReturn
  def on_def(node)
    super unless contract?(node)
  end

  def on_defs(node)
    super unless contract?(node)
  end

  private

  def contract?(node) = Array(cop_config["AllowedMethods"]).map(&:to_s).include?(node.method_name.to_s)
end
