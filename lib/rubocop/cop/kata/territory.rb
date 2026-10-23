# frozen_string_literal: true

module RuboCop::Cop::Kata::Territory
  private

  def root?(name) = roots.include?(spelled(name))

  def claimed?(name)
    held = spelled(name)
    claims.any? { |claim| under?(held, claim) && roots.none? { under?(it, claim) } }
  end

  def roots = @_roots ||= Array(cop_config["Roots"]).map { spelled(it) }

  def claims = @_claims ||= Array(cop_config["Dependencies"]).map { claim(it.to_s) }

  def claim(gem) = gem.downcase.split("-").map { it.delete("_.") }.join("::")

  def under?(name, root) = name == root || name.start_with?("#{root}::")

  def spelled(name) = name.to_s.downcase.delete("_")
end
