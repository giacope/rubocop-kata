# frozen_string_literal: true

class RuboCop::Cop::Kata::GoodMethodName < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Wording
  include RuboCop::Cop::Kata::Minting

  MSG = "`%s` strings %d words together, past the %d a name carries: a concept is missing, or the " \
    "method belongs on the object the words describe. Say it in fewer, move it, give a role a " \
    "`Prefixes`/`Suffixes` word — or, if `%s` is one domain concept here, add it to `Terms`."
  CHAIN_MSG = "`%s` chains actions with `%s`; each action wants its own method."
  JOINTS = %w[and or then].freeze
  SUITE = /Test(Case)?\z/
  RESTRICT_ON_SEND = RuboCop::Cop::Kata::Minting::MINTERS

  def on_def(node) = test?(node) || check(node.loc.name, node.method_name)

  def on_defs(node) = check(node.loc.name, node.method_name)

  private

  def mint(range, name) = check(range, name)

  def check(range, name)
    text = name.to_s
    stem = text.sub(/[?!=]\z/, "")
    judge(range, name, stem) { chain(name, stem) } if text.match?(/\A[a-z_]/)
  end

  def test?(node) = node.method_name.start_with?("test_") && node.each_ancestor(:class).take(1).any? { suite?(it) }

  def suite?(klass) = [klass.identifier, klass.parent_class].compact.any? { SUITE.match?(it.source) }

  def chain(name, stem)
    joint = (stem.split("_") & JOINTS).first
    format(CHAIN_MSG, name, joint) if joint
  end
end
