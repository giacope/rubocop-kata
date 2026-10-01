# frozen_string_literal: true

class RuboCop::Cop::Kata::GoodClassName < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::TypeName

  BANNED_MSG = "`%s` is a junk drawer; it hides the concept the code is missing."
  CROWD_MSG = "`%s` packs %d concepts into one name; a class names one object that exists " \
    "in the model — or, if `%s` reads as one concept here, add it to `Terms`."

  def on_class(node) = check(node)

  private

  def subject(name)
    role = list("Suffixes").find { name.end_with?(it) }
    role ? name.delete_suffix(role) : name
  end
end
