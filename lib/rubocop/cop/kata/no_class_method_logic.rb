# frozen_string_literal: true

class RuboCop::Cop::Kata::NoClassMethodLogic < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster

  MSG = "`%s` puts logic on the class; classes construct, instances work."

  def on_defs(node) = check(node)

  def on_def(node)
    check(node) if node.each_ancestor(:sclass, :class, :module, :any_block).first&.sclass_type?
  end

  private

  def check(node)
    name = node.method_name.to_s
    return if constructor?(name)
    add_offense(node.loc.name, message: format(MSG, name))
  end

  def constructor?(name) = name.start_with?("from_") || allowed?(name)
end
