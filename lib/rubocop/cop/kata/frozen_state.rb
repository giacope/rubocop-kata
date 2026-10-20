# frozen_string_literal: true

class RuboCop::Cop::Kata::FrozenState < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Memoization
  include RuboCop::Cop::Kata::Roster

  MSG = "`%s` changes after construction; set state once in `initialize` and return a new object to change it."
  CONSTRUCTORS = %i[initialize initialize_copy initialize_dup initialize_clone].freeze
  RESTRICT_ON_SEND = %i[instance_variable_set].freeze

  def_node_matcher :minted, "(any_block (send {nil? self} :define_method ${sym str dsym} ...) ...)"
  def_node_matcher :injected, "(send {nil? self} :instance_variable_set ${sym str dsym} _)"

  def on_ivasgn(node) = judge(node, node.loc.name, node.children.first)

  def on_send(node)
    injected(node) { |name| judge(node, node, name.dsym_type? ? name.source : name.value) }
  end

  private

  def judge(node, range, name)
    method = node.each_ancestor(:def, :defs).first
    return dynamic(node, range, name) if method.nil?
    return if class_level?(method) || builder?(method) || cached?(node)
    add_offense(range, message: format(MSG, name))
  end

  def dynamic(node, range, name)
    named = node.each_ancestor(:any_block).filter_map { minted(it) }.first
    return if named.nil? || (!named.dsym_type? && CONSTRUCTORS.include?(named.value.to_sym)) || cached?(node)
    add_offense(range, message: format(MSG, name))
  end

  def cached?(node) = node.ivasgn_type? && memoized?(node)

  def class_level?(method)
    method.defs_type? || method.each_ancestor(:sclass, :class, :module).first&.sclass_type?
  end

  def builder?(method)
    name = method.method_name
    return true if listed?("ConstructorHooks", name.to_s)
    scope = method.each_ancestor(:class, :module, :any_block).first
    return builders([method]).include?(name) unless scope
    lineage(scope).any? { builders(it.each_descendant(:def).to_a).include?(name) }
  end

  def lineage(scope)
    found = [scope]
    while (base = base(found.last)) && !found.include?(base)
      found << base
    end
    found
  end

  def base(scope)
    parent = scope.parent_class if scope.class_type?
    return unless parent&.const_type?
    processed_source.ast.each_node(:class).find { it.identifier.short_name == parent.short_name }
  end

  def builders(methods)
    found = CONSTRUCTORS
    loop do
      called = methods.select { found.include?(it.method_name) }.flat_map { helpers(it) }
      return found if (called - found).empty?
      found |= called
    end
  end

  def helpers(method) = method.each_descendant(:send).select { it.receiver.nil? }.map(&:method_name)
end
