# frozen_string_literal: true

class RuboCop::Cop::Kata::GoodModuleName < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::TypeName

  BANNED_MSG = "`%s` names a layer or a junk drawer; a module names a domain vocabulary."
  CROWD_MSG = "`%s` packs %d concepts into one name; a module names one domain — " \
    "or, if `%s` reads as one concept here, add it to `Terms`."

  def on_module(node) = check(node)
end
