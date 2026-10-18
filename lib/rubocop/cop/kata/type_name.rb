# frozen_string_literal: true

module RuboCop::Cop::Kata::TypeName
  include RuboCop::Cop::Kata::AgentNoun
  include RuboCop::Cop::Kata::Roster

  private

  def check(node)
    identifier = node.identifier
    name = subject(identifier.short_name.to_s)
    return if allowed?(name)
    complaint = complaint(name, node)
    add_offense(identifier, message: complaint) if complaint
  end

  def complaint(name, node)
    return format(self.class::BANNED_MSG, name) if banned?(name)
    return doer(name, node.type) if doer?(name) && !heir?(name, node)
    crowd(name)
  end

  def crowd(name)
    count = name.scan(SEGMENT).size
    format(self.class::CROWD_MSG, name, count, name) if count > max
  end

  def subject(name)
    stem = strip(name, list("Suffixes"))
    strip(stem, list("ContractSuffixes") + (stem == name ? [] : contracts))
  end

  def strip(name, roles)
    role = roles.find { name.end_with?(it) && name != it }
    role ? name.delete_suffix(role) : name
  end

  def contracts = Array(config.for_cop("Kata/GoodModuleName")["ContractSuffixes"]).map(&:to_s)

  def heir?(name, node) = inherited?(name, node) || tested_heir?(name, node)

  def inherited?(name, node)
    parent = node.parent_class if node.class_type?
    return false unless parent&.const_type?
    same_role?(parent.short_name.to_s, name)
  end

  def tested_heir?(name, node)
    tested = node.identifier.short_name.to_s
    return false unless strip(tested, list("Suffixes")) == name && tested != name
    list("FrameworkSuperclasses").any? { same_role?(it, name) }
  end

  def same_role?(parent, name) = parent.scan(SEGMENT).last == name.scan(SEGMENT).last

  def banned?(name) = list("BannedNames").any? { name.end_with?(it) }

  def allowed?(name) = list("AllowedNames").any? { name.end_with?(it) } || listed?("Terms", name)

  def max = Integer(cop_config.fetch("MaxWords", 2))
end
