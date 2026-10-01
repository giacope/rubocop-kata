# frozen_string_literal: true

class RuboCop::Cop::Kata::GoodMethodName < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Wording

  MSG = "`%s` needs two words: either a concept is missing, or the method belongs on the object " \
    "the second word names. Say it in one word, move it, give the role a `Prefixes`/`Suffixes` " \
    "word — or, if `%s` is one domain concept here, add it to `Terms`."
  CHAIN_MSG = "`%s` chains actions with `%s`; each action wants its own method."
  JOINTS = %w[and or then].freeze
  SUITE = /Test(Case)?\z/

  def on_def(node) = test?(node) || check(node, node.method_name)

  def on_defs(node) = check(node, node.method_name)

  private

  def check(node, name)
    text = name.to_s
    stem = text.sub(/[?!=]\z/, "")
    return if !text.match?(/\A[a-z_]/) || allowed?(text) || allowed?(stem)
    complaint = chain(name, stem) || (format(MSG, name, name) unless good?(stem))
    add_offense(node.loc.name, message: complaint) if complaint
  end

  def test?(node) = node.method_name.start_with?("test_") && node.each_ancestor(:class).take(1).any? { suite?(it) }

  def suite?(klass) = [klass.identifier, klass.parent_class].compact.any? { SUITE.match?(it.source) }

  def chain(name, stem)
    joint = (stem.split("_") & JOINTS).first
    format(CHAIN_MSG, name, joint) if joint
  end
end
