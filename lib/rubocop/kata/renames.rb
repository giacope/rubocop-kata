# frozen_string_literal: true

class RuboCop::Kata::Renames
  def initialize(rules = RuboCop::ConfigObsoletion.global.rules)
    @rules = rules
  end

  def to(name) = table[name]

  private

  def table = @_table ||= @rules.select { it.respond_to?(:new_name) }.to_h { [it.old_name, it.new_name] }
end
