# frozen_string_literal: true

module RuboCop::Cop::Kata::Affiliation
  include RuboCop::Cop::Kata::Pedigree

  private

  def posed(node)
    return unless cop_config["CheckContracts"] && !record?(node)
    role = role(node.identifier.short_name.to_s)
    role if role && !affiliated?(node, role)
  end

  def role(name)
    list("ContractSuffixes").find { name.end_with?(it) && name != it && RuboCop::Kata::Agency.new(it).suffixed? }
  end

  def affiliated?(node, role)
    words = [role, "#{role}s"].map(&:downcase)
    patrons(node).any? { |patron| words(patron).intersect?(words) }
  end

  def words(patron) = patron.scan(/[A-Za-z0-9]+/).flat_map { [it, *segments(it)] }.flat_map { it.downcase.split("_") }

  def patrons(node)
    qualified = RuboCop::Kata::Nesting.new(node).qualified
    [node.parent_class&.source.to_s, *project.ancestors(qualified).drop(1), qualified.sub(/(?:\A|::)\w+\z/, ""), folder]
  end

  def folder = File.dirname(processed_source.file_path.to_s).delete_prefix(config.base_dir_for_path_parameters)
end
