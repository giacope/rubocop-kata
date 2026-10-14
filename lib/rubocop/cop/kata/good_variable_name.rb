# frozen_string_literal: true

class RuboCop::Cop::Kata::GoodVariableName < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Wording

  MSG = "`%s` strings %d words together, past the %d a name carries: the words describe an object " \
    "you have not introduced yet. Name that object, give a role a `Prefixes`/`Suffixes` word — or, " \
    "if `%s` is one domain concept here, add it to `Terms`."

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
    stem = name.to_s.sub(SIGIL, "").delete_prefix("_")
    judge(node.loc.name, name, stem)
  end
end
