# frozen_string_literal: true

class RuboCop::Cop::Kata::BuilderNoun < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster
  include RuboCop::Cop::Kata::Contract
  include RuboCop::Cop::Kata::Ancestry

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
    !(allowed?(name) || inherited?(node) || foreign?(name) || override?(node) || command?(node))
  end

  def prefix(name) = list("BannedPrefixes").find { name.start_with?("#{it}_") }

  def command?(node)
    last = final(node)
    last&.call_type? ? list("Commands").intersect?(spelled(last)) : false
  end

  def final(node)
    last = node.body&.then { it.begin_type? ? it.children.last : it }
    last&.any_block_type? ? last.send_node : last
  end

  def spelled(call)
    name = call.method_name.to_s
    return [name] if call.receiver.nil?
    owner = call.receiver.const_name
    [owner, "#{owner}.#{name}"]
  end
end
