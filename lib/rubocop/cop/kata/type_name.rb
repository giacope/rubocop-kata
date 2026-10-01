# frozen_string_literal: true

module RuboCop::Cop::Kata::TypeName
  include RuboCop::Cop::Kata::AgentNoun
  include RuboCop::Cop::Kata::Roster

  private

  def check(node)
    identifier = node.identifier
    name = subject(identifier.short_name.to_s)
    return if allowed?(name)
    complaint = complaint(name, node.type)
    add_offense(identifier, message: complaint) if complaint
  end

  def complaint(name, kind)
    return format(self.class::BANNED_MSG, name) if banned?(name)
    return doer(name, kind) if doer?(name)
    crowd(name)
  end

  def crowd(name)
    count = name.scan(SEGMENT).size
    format(self.class::CROWD_MSG, name, count, name) if count > max
  end

  def subject(name) = name

  def banned?(name) = list("BannedNames").any? { name.end_with?(it) }

  def allowed?(name) = list("AllowedNames").any? { name.end_with?(it) } || listed?("Terms", name)

  def max = Integer(cop_config.fetch("MaxWords", 2))
end
