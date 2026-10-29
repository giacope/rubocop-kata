# frozen_string_literal: true

module RuboCop::Cop::Kata::Pedigree
  private

  def project
    @_project ||= sources.lineage.merge(RuboCop::Kata::Lineage.parse(processed_source.raw_source))
  end

  def inheritance = RuboCop::Kata::Inheritance.new(project)

  def sources = RuboCop::Kata::Sources.of(config.base_dir_for_path_parameters, list("OwnedPaths"))

  def inventory = RuboCop::Kata::Inventory.of(config.base_dir_for_path_parameters, list("OwnedPaths"))

  def repertoire = RuboCop::Kata::Repertoire.of(sources)
end
