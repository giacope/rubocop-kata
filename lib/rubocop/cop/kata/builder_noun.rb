# frozen_string_literal: true

class RuboCop::Cop::Kata::BuilderNoun < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster
  include RuboCop::Cop::Kata::Contract
  include RuboCop::Cop::Kata::Ancestry
  include RuboCop::Cop::VisibilityHelp

  MSG = "A builder is named for what it returns: `%s`, not `%s`."

  def on_def(node) = check(node)

  def on_defs(node) = check(node)

  private

  def check(node)
    name = node.method_name.to_s
    verb = prefix(name)
    return unless verb && builder?(node, name)
    add_offense(node.loc.name, message: format(MSG, name.delete_prefix("#{verb}_"), name))
  end

  def builder?(node, name)
    return false if name.end_with?("?") || allowed?(name) || inherited?(node) || foreign?(name)
    !(override?(node) || command?(node) || step?(node))
  end

  def prefix(name) = list("BannedPrefixes").find { name.start_with?("#{it}_") }

  def command?(node) = node.each_descendant(:send, :csend).any? { list("Commands").intersect?(spelled(it)) }

  def step?(node)
    holder = node.parent&.then { it.begin_type? ? it.parent : it }
    return false unless node.def_type? && holder&.class_type? && node_visibility(node) == :public
    project.ancestors(RuboCop::Kata::Nesting.new(holder).qualified).intersect?(list("StepSuperclasses"))
  end

  def spelled(call)
    name = call.method_name.to_s
    return [name] if call.receiver.nil?
    owner = call.receiver.const_name
    [owner, "#{owner}.#{name}"]
  end
end
