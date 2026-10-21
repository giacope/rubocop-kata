# frozen_string_literal: true

module RuboCop::Cop::Kata::Ancestry
  private

  def project
    @_project ||= RuboCop::Kata::Inventory.of(config.base_dir_for_path_parameters, list("OwnedPaths")).lineage
      .merge(RuboCop::Kata::Lineage.parse(processed_source.raw_source))
  end
end
