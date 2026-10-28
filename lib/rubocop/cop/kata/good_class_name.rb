# frozen_string_literal: true

class RuboCop::Cop::Kata::GoodClassName < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::TypeName
  include RuboCop::Cop::Kata::Affiliation

  BANNED_MSG = "`%s` is a junk drawer; it hides the concept the code is missing."
  CROWD_MSG = "`%s` packs %d concepts into one name; a class names one object that exists " \
    "in the model — or, if `%s` reads as one concept here, add it to `Terms`."
  POSED_MSG = "`%s` names a doer: `%s` is a framework's word only where a superclass or mixin takes part in " \
    "that contract, and none does here; name the class for the thing it is, not the work it does."

  def on_class(node)
    check(node) unless wrapper?(node)
  end

  private

  def subject_of(node) = posed(node) ? node.identifier.short_name.to_s : super

  def complaint(name, node)
    role = posed(node)
    role ? format(POSED_MSG, name, role) : super
  end

  def wrapper?(node)
    body = node.body
    return false if body.nil?
    (body.begin_type? ? body.children : [body]).all? { it.class_type? || it.module_type? }
  end
end
