# frozen_string_literal: true

class RuboCop::Cop::Kata::EnvDiscipline < RuboCop::Cop::Base
  MSG = "`ENV` belongs in the boot layer; pass configuration in."

  def on_const(node)
    return unless node.short_name == :ENV && node.each_path.all?(&:cbase_type?)
    add_offense(node, message: MSG) unless seam?(node)
  end

  private

  def seam?(node) = node.each_ancestor(:optarg, :kwoptarg).any?
end
