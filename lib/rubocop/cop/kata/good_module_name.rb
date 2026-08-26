# frozen_string_literal: true

class RuboCop::Cop::Kata::GoodModuleName < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::AgentNoun

  LAYER_MSG = "`%s` names a layer or a junk drawer; a module names a domain vocabulary."
  CROWD_MSG = "`%s` packs %d concepts into one name; a module names one domain — " \
    "or, if `%s` reads as one concept here, add it to `Terms`."

  def on_module(node) = check(node)

  private

  def check(node)
    name = node.identifier.short_name.to_s
    return if allowed?(name)
    complaint = complaint(name)
    add_offense(node.identifier, message: complaint) if complaint
  end

  def complaint(name)
    return format(LAYER_MSG, name) if banned?(name)
    return doer(name) if doer?(name)
    crowd(name)
  end

  def crowd(name)
    count = name.scan(SEGMENT).size
    format(CROWD_MSG, name, count, name) if count > max
  end

  def kind = "module"

  def banned?(name) = list("BannedNames").any? { name.end_with?(it) }

  def allowed?(name) = list("AllowedNames").any? { name.end_with?(it) } || list("Terms").include?(name)

  def list(key) = Array(cop_config[key]).map(&:to_s).reject(&:empty?)

  def max = Integer(cop_config.fetch("MaxWords", 2))
end
