# frozen_string_literal: true

module RuboCop::Cop::Kata::Ownership
  include RuboCop::Cop::Kata::Roster
  include RuboCop::Cop::Kata::Territory

  private

  def own?(probe) = probe&.const_type? && owners(probe).any?

  def owners(probe) = candidates(probe).select { owned?(it) }

  def candidates(probe) = probe.absolute? ? [probe.const_name] : spellings(probe.const_name, probe)

  def spellings(name, node) = RuboCop::Kata::Nesting.new(node).candidates(name)

  def own_name?(name, node) = spellings(name, node).any? { owned?(it) }

  def namespace?(name) = local_types.any? { it.start_with?("#{name}::") } || inventory.namespace?(name)

  def owned?(name) = !foreign?(name) && (local_types.include?(name) || inventory.type?(name))

  def foreign?(name) = RuboCop::Kata::Dictionary::CORE.include?(name) || claimed?(name)

  def answered?(name) = local_methods.include?(name) || inventory.message?(name)

  def local_methods = @_local_methods ||= processed_source.ast.each_node(:def, :defs).to_set(&:method_name)

  def local_types = @_local_types ||= RuboCop::Kata::Definitions.new(processed_source.raw_source).names

  def inventory = RuboCop::Kata::Inventory.of(config.base_dir_for_path_parameters, list("OwnedPaths"))
end
