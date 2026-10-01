# frozen_string_literal: true

module RuboCop::Cop::Kata::Roster
  private

  def allowed?(name) = listed?("AllowedNames", name)

  def listed?(key, name) = list(key).include?(name)

  def list(key) = Array(cop_config[key]).map(&:to_s).reject(&:empty?)
end
