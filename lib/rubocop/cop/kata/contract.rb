# frozen_string_literal: true

module RuboCop::Cop::Kata::Contract
  OWNED = %w[app/**/*.rb */app/**/*.rb lib/**/*.rb */lib/**/*.rb].freeze

  private

  def inherited?(node) = node.each_descendant(:super, :zsuper).any? { it.each_ancestor(:def, :defs).first.equal?(node) }

  def foreign?(name)
    RuboCop::Kata::Inventory.of(config.base_dir_for_path_parameters, cop_config.fetch("OwnedPaths", OWNED))
      .foreign?(name)
  end
end
