# frozen_string_literal: true

module RuboCop::Cop::Kata::Pedigree
  private

  def project
    @_project ||= inventory.lineage.merge(RuboCop::Kata::Lineage.parse(processed_source.raw_source))
  end

  def inventory = RuboCop::Kata::Inventory.of(config.base_dir_for_path_parameters, list("OwnedPaths"))
end
