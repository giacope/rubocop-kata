# frozen_string_literal: true

module RuboCop::Cop::Kata::Ownership
  private

  def own?(name) = local.include?(name) || inventory.message?(name)

  def owned?(const)
    name = const.const_name
    candidates = const.absolute? ? [name] : [*RuboCop::Kata::Nesting.new(const).names.map { "#{it}::#{name}" }, name]
    candidates.any? { !RuboCop::Kata::Dictionary::CORE.include?(it) && (types.include?(it) || inventory.type?(it)) }
  end

  def local = @_local ||= processed_source.ast.each_node(:def, :defs).to_set(&:method_name)

  def types = @_types ||= RuboCop::Kata::Definitions.new(processed_source.raw_source).names

  def inventory = RuboCop::Kata::Inventory.of(config.base_dir_for_path_parameters, Array(cop_config["OwnedPaths"]))
end
