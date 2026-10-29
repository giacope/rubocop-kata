# frozen_string_literal: true

class RuboCop::Kata::Renames
  def initialize(rules = RuboCop::ConfigObsoletion.global.rules)
    @rules = rules
  end

  def renamed?(name) = table.key?(name)

  def to(name) = table.fetch(name)

  private

  def table = @_table ||= @rules.select { it.respond_to?(:new_name) }.to_h { [it.old_name, it.new_name] }
end
