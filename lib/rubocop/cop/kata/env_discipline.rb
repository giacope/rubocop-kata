# frozen_string_literal: true

class RuboCop::Cop::Kata::EnvDiscipline < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::BootLayer
  include RuboCop::Cop::Kata::Roster

  MSG = "`%s` belongs in the boot layer; pass configuration in."

  def on_const(node)
    return unless node.short_name == :ENV && node.each_path.all?(&:cbase_type?)
    add_offense(node, message: format(MSG, "ENV")) unless seam?(node)
  end

  def on_send(node)
    name = "#{node.receiver&.source&.delete_prefix("::")}.#{node.method_name}"
    return unless listed?("Settings", name) && !seam?(node) && !node.parent&.defined_type?
    add_offense(node, message: format(MSG, name))
  end
end
