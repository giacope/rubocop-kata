# frozen_string_literal: true

class RuboCop::Cop::Kata::BuilderNoun < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster

  MSG = "A builder is named for what it returns: `%s`, not `%s`."

  def on_def(node) = check(node)

  def on_defs(node) = check(node)

  private

  def check(node)
    name = node.method_name.to_s
    return if allowed?(name)
    verb = prefix(name)
    add_offense(node.loc.name, message: format(MSG, name.delete_prefix("#{verb}_"), name)) if verb
  end

  def prefix(name) = list("BannedPrefixes").find { name.start_with?("#{it}_") }
end
