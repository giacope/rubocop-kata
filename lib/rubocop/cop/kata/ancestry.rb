# frozen_string_literal: true

module RuboCop::Cop::Kata::Ancestry
  private

  def override?(node)
    scope = node.each_ancestor(:class, :module).first
    return false unless scope
    name = node.method_name.to_s
    project.ancestors(RuboCop::Kata::Nesting.new(scope).qualified).drop(1).any? { project.defines?(it, name) }
  end

  def project
    @_project ||= RuboCop::Kata::Inventory.of(config.base_dir_for_path_parameters, list("OwnedPaths")).lineage
      .merge(RuboCop::Kata::Lineage.parse(processed_source.raw_source))
  end
end
