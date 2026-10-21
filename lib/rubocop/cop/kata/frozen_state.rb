# frozen_string_literal: true

class RuboCop::Cop::Kata::FrozenState < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Memoization
  include RuboCop::Cop::Kata::Roster
  include RuboCop::Cop::Kata::Ancestry

  MSG = "`%s` changes after construction; set state once in `initialize` and return a new object to change it."
  CONSTRUCTORS = %i[initialize initialize_copy initialize_dup initialize_clone].freeze
  LOOKUPS = %i[key? include? has_key? member? []].freeze

  def_node_matcher :minted, "(any_block (send {nil? self} :define_method ${sym str dsym} ...) ...)"
  def_node_matcher :injected, "(send {nil? self} :instance_variable_set ${sym str dsym} _)"

  def on_ivasgn(node) = judge(node, node.loc.name, node.children.first)

  def on_send(node)
    injected(node) { |name| judge(node, node, name.dsym_type? ? name.source : name.value) }
    receiver = node.receiver
    judge(node, node, receiver.children.first) if receiver&.ivar_type? && mutation?(node)
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

  def cached?(node) = node.ivasgn_type? && (memoized?(node) || declared?(node))

  def declared?(node)
    return false unless cop_config["Sorbet"] == true
    typed = RuboCop::Kata::Annotation.new(node.expression)
    typed.wrapper? && typed.value == s(:ivar, node.children.first)
  end

  def class_level?(method)
    method.defs_type? || method.each_ancestor(:sclass, :class, :module).first&.sclass_type?
  end

  def mutation?(node)
    mutating?(node.method_name) && !stored?(node)
  end

  def mutating?(name)
    Array(config.for_cop("Kata/NoOutputArgument")["MutatingMethods"]).map(&:to_s).include?(name.to_s)
  end

  def stored?(node)
    guard = node.each_ancestor(:if).first
    node.method?(:[]=) && !guard.nil? && guard.condition.each_node(:send).any? { lookup?(it, node.receiver) }
  end

  def lookup?(call, cache) = LOOKUPS.include?(call.method_name) && call.receiver == cache

  def builder?(method)
    name = method.method_name
    scope = method.each_ancestor(:class, :module, :any_block).first
    return true if hooks(scope).include?(name.to_s)
    return builders([method]).include?(name) unless scope
    return true if lineage(scope).any? { builders(it.each_descendant(:def).to_a).include?(name) }
    constructed?(scope, name.to_s)
  end

  def hooks(scope)
    names = list("ConstructorHooks")
    return names unless scope&.type?(:class, :module)
    names + names.select { it.include?("#") }.map { qualified_hook(it, scope) }.compact
  end

  def qualified_hook(entry, scope)
    owner, hook = entry.split("#", 2)
    ancestors = project.ancestors(RuboCop::Kata::Nesting.new(scope).qualified)
    hook if ancestors.any? { it == owner || it.start_with?("#{owner}::") }
  end

  def constructed?(scope, name)
    return false unless scope.type?(:class, :module)
    project.constructed(RuboCop::Kata::Nesting.new(scope).qualified, hooks(scope).sort).include?(name)
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
