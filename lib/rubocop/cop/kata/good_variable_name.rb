# frozen_string_literal: true

class RuboCop::Cop::Kata::GoodVariableName < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Wording

  MSG = "`%s` needs two words: the second word names an object you have not introduced yet. " \
    "Name that object, use a `Prefixes`/`Suffixes` role word — or, if `%s` is one domain concept " \
    "here, add it to `Terms`."

  SIGIL = /\A(@@|@|\$)/

  def on_lvasgn(node) = check(node, node.name)

  def on_ivasgn(node) = check(node, node.name)

  def on_cvasgn(node) = check(node, node.name)

  def on_gvasgn(node) = check(node, node.name)

  def on_arg(node) = check(node, node.name)

  def on_optarg(node) = check(node, node.name)

  def on_kwarg(node) = check(node, node.name)

  def on_kwoptarg(node) = check(node, node.name)

  def on_restarg(node) = check(node, node.name)

  def on_kwrestarg(node) = check(node, node.name)

  def on_blockarg(node) = check(node, node.name)

  private

  def check(node, name)
    text = name.to_s
    stem = text.sub(SIGIL, "").delete_prefix("_")
    return if allowed?(text) || allowed?(stem) || stem.empty? || good?(stem)
    add_offense(node.loc.name, message: format(MSG, name, name))
  end
end
