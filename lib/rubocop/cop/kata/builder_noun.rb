# frozen_string_literal: true

class RuboCop::Cop::Kata::BuilderNoun < RuboCop::Cop::Base
  MSG = "A builder is named for what it returns: `%s`, not `%s`."

  def on_def(node) = check(node)

  def on_defs(node) = check(node)

  private

  def check(node)
    name = node.method_name.to_s
    verb = prefix(name)
    return unless verb
    add_offense(node.loc.name, message: format(MSG, name.delete_prefix("#{verb}_"), name))
  end

  def prefix(name)
    Array(cop_config["BannedPrefixes"]).map(&:to_s).find { name.start_with?("#{it}_") }
  end
end
