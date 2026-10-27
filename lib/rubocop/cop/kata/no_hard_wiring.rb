# frozen_string_literal: true

class RuboCop::Cop::Kata::NoHardWiring < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster
  include RuboCop::Cop::Kata::Ownership
  include RuboCop::Cop::Kata::Assembly
  include RuboCop::Cop::Kata::Lifetime

  MSG = "`%s` builds the `%s` it talks to; "
  KEPT = "`%s` builds the `%s` it keeps in `%s`; "
  HANDED = "`%s` builds the `%s` it hands to `%s`; "
  CONSTRUCTORS = %i[initialize initialize_copy].freeze
  GLOBALS = %i[const gvar cvar].freeze

  RESTRICT_ON_SEND = %i[new].freeze

  def on_send(node)
    method = node.each_ancestor(:def, :defs).first
    return unless method && candidate?(node, method)
    message, place = finding(node, method)
    return unless message
    add_offense(node, message: format(message, method.method_name, node.receiver.const_name, place) + seam(method))
  end

  private

  def candidate?(node, method)
    return false unless instance?(method) && node.each_ancestor(:optarg, :kwoptarg).none?
    target = node.receiver
    home = home(method)
    own?(target) && !owners(target).include?(home) && !root?(home)
  end

  def finding(node, method)
    built = built(node)
    place = kept(built, method)
    return [KEPT, place] if place
    holder = built.parent
    found = maker(built, holder, method)
    return [HANDED, "#{found.receiver.source}.new"] if found && handed_on?(node, found, holder, method)
    [MSG] if !wraps?(node) && talked?(node, built, method)
  end

  def handed_on?(node, found, holder, method)
    return outlives?(found, method) && !candidate?(found, method) if wraps?(node)
    !scratch?(node, holder, method)
  end

  def wraps?(node)
    parts = node.arguments
    parts.any? { !it.recursive_basic_literal? } && parts.none? { |part| part.each_node(*GLOBALS).any? { outside?(it) } }
  end

  def outside?(part) = !part.const_type? || !part.namespace.nil? || !named?(part.short_name)

  def named?(name) = processed_source.ast.each_node(:casgn).any? { it.short_name == name }

  def instance?(method)
    method.def_type? && !CONSTRUCTORS.include?(method.method_name) && method.each_ancestor(:sclass).none?
  end
end
