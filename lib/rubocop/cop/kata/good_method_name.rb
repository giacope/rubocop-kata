# frozen_string_literal: true

class RuboCop::Cop::Kata::GoodMethodName < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Wording
  include RuboCop::Cop::Kata::Minting
  include RuboCop::Cop::Kata::Ancestry
  include RuboCop::Cop::Kata::Contract

  MSG = "`%s` strings %d words together, past the %d a name carries: a concept is missing, or the " \
    "method belongs on the object the words describe. Say it in fewer, move it, give a role a " \
    "`Prefixes`/`Suffixes` word — or, if `%s` is one domain concept here, add it to `Terms`."
  CHAIN_MSG = "`%s` chains actions with `%s`; each action wants its own method."
  JOINTS = %w[and or then].freeze
  SUITE = /Test(Case)?\z/

  def on_def(node)
    klass = node.each_ancestor(:class).first
    suite = klass && [klass.identifier, klass.parent_class].compact.any? { SUITE.match?(it.source) }
    return if (node.method_name.start_with?("test_") && suite) || override?(node) || inherited?(node)
    check(node.loc.name, node.method_name)
  end

  def on_defs(node) = (check(node.loc.name, node.method_name) unless inherited?(node))

  private

  def mint(range, name) = check(range, name)

  def check(range, name)
    text = name.to_s
    return if !text.match?(/\A[a-z_]/) || foreign?(text)
    stem = text.sub(/[?!=]\z/, "").sub(/\A_+/, "")
    words = core(stem.split("_"))
    joints = words[1...-1].to_a.select { JOINTS.include?(it) }.first(1)
    judge(range, name, stem, joints.map { format(CHAIN_MSG, name, it) })
  end
end
