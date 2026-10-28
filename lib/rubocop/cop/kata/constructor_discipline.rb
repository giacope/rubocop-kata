# frozen_string_literal: true

class RuboCop::Cop::Kata::ConstructorDiscipline < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster
  include RuboCop::Cop::Kata::Tally

  MSG = "A constructor assigns; it does not compute. Move %s out of `initialize`."
  PATHS = "`initialize` picks a way to build itself from %s: several constructors in one. %s"
  PRIMARY = "Keep one primary constructor, and give each other way a class method that calls `new`."
  BYPASS = "`allocate` builds an instance past `initialize`, a second primary constructor; call `new` instead."
  BRANCHES = %i[if case case_match].freeze

  RESTRICT_ON_SEND = %i[allocate].freeze
  CONVERSION = /\Ato_[a-z]+\z/
  FRESH = %i[+@ -@ compare_by_identity].freeze
  LITERALS = %i[str dstr hash array].freeze

  def on_def(node)
    return unless node.method?(:initialize) && node.body
    computed(node)
    paths(node) if paths?
  end

  def on_send(node)
    return unless paths? && (node.receiver.nil? || node.receiver.self_type?)
    add_offense(node, message: BYPASS) if node.each_ancestor(:defs, :sclass).any?
  end

  private

  def paths? = cop_config["CheckPaths"]

  def computed(node)
    moved = node.body.each_node(:send, :csend).reject { allowed?(it) || exempt?(it, node) || typing?(it) }
    add_offense(moved.first, message: format(MSG, tally(moved.map(&:method_name)))) unless moved.empty?
  end

  def paths(node)
    inputs = node.arguments.map(&:name)
    branches = node.body.each_node(*BRANCHES).reject { guard?(it) }.select { asked(it, inputs).any? }
    return if branches.empty?
    add_offense(branches.first.condition, message: format(PATHS, named(branches, inputs), PRIMARY))
  end

  def named(branches, inputs) = joined(branches.flat_map { asked(it, inputs) }.uniq.map { "`#{it}`" })

  def asked(branch, inputs)
    test = branch.condition
    return [] unless test
    [test, *test.each_descendant(:lvar)].select(&:lvar_type?).map { it.children.first }.uniq & inputs
  end

  def allowed?(send)
    name = send.method_name.to_s
    listed?("AllowedMethods", name) || CONVERSION.match?(name) || state?(send) || written?(send)
  end

  def written?(send) = send.receiver&.self_type? && send.setter_method? && !send.method?(:[]=)

  def state?(send)
    receiver = send.receiver
    return own?(receiver) if FRESH.include?(send.method_name)
    send.method?(:new) && receiver&.const_type? && listed?("AllowedConstructors", receiver.const_name)
  end

  def own?(receiver)
    receiver = receiver.send_node if receiver&.any_block_type?
    return true if receiver.nil?
    LITERALS.include?(receiver.type) || (receiver.send_type? && state?(receiver))
  end

  def exempt?(send, root)
    send.each_ancestor.take_while { !it.equal?(root) }.any? { deferred?(it) || raised?(it) || guard?(it) }
  end

  def typing?(send) = cop_config["Sorbet"] == true && RuboCop::Kata::Annotation.new(send).typing?

  def deferred?(node) = node.any_block_type? && (node.lambda_or_proc? || state?(node.send_node))

  def raised?(node) = node&.send_type? && listed?("RaisingMethods", node.method_name.to_s)

  def guard?(node) = node.if_type? && node.branches.all? { raised?(it) }
end
