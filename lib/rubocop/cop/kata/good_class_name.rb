# frozen_string_literal: true

class RuboCop::Cop::Kata::GoodClassName < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::AgentNoun

  BUCKET_MSG = "`%s` is a junk drawer; it hides the concept the code is missing."
  CROWD_MSG = "`%s` packs %d concepts into one name; a class names one object that exists " \
    "in the model — or, if `%s` reads as one concept here, add it to `Terms`."

  def on_class(node) = check(node)

  private

  def check(node)
    name = subject(node.identifier.short_name.to_s)
    return if allowed?(name)
    complaint = complaint(name)
    add_offense(node.identifier, message: complaint) if complaint
  end

  def complaint(name)
    return format(BUCKET_MSG, name) if banned?(name)
    return doer(name) if doer?(name)
    crowd(name)
  end

  def crowd(name)
    count = name.scan(SEGMENT).size
    format(CROWD_MSG, name, count, name) if count > max
  end

  def kind = "class"

  def subject(name)
    role = list("Suffixes").find { name.end_with?(it) }
    role ? name.delete_suffix(role) : name
  end

  def banned?(name) = list("BannedNames").any? { name.end_with?(it) }

  def allowed?(name) = list("AllowedNames").any? { name.end_with?(it) } || list("Terms").include?(name)

  def list(key) = Array(cop_config[key]).map(&:to_s).reject(&:empty?)

  def max = Integer(cop_config.fetch("MaxWords", 2))
end
