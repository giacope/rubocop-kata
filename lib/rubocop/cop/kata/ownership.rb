# frozen_string_literal: true

module RuboCop::Cop::Kata::Ownership
  include RuboCop::Cop::Kata::Territory

  private

  def own?(probe) = probe&.const_type? && owners(probe).any?

  def owners(probe)
    name = probe.const_name
    candidates = probe.absolute? ? [name] : [*RuboCop::Kata::Nesting.new(probe).names.map { "#{it}::#{name}" }, name]
    candidates.select { owned?(it) }
  end

  def owned?(name) = !foreign?(name) && (local_types.include?(name) || inventory.type?(name))

  def foreign?(name) = RuboCop::Kata::Dictionary::CORE.include?(name) || claimed?(name)

  def local_types = @_local_types ||= RuboCop::Kata::Definitions.new(processed_source.raw_source).names

  def inventory = RuboCop::Kata::Inventory.of(config.base_dir_for_path_parameters, list("OwnedPaths"))
end
