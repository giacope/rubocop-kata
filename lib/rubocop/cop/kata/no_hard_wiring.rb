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
  TYPE = /[a-z]/
  MODULES = %i[CGI CSV ERB IO JSON URI YAML].freeze
  HOOKS = %i[included inherited prepended extended].freeze

  RESTRICT_ON_SEND = %i[new].freeze

  def on_send(node)
    method = node.each_ancestor(:def, :defs).first
    return unless method && candidate?(node, method)
    findings(node, method).each do |message, place|
      add_offense(node, message: format(message, method.method_name, node.receiver.const_name, place) + seam(method))
    end
  end

  private

  def candidate?(node, method)
    return false unless instance?(method) && node.each_ancestor(:optarg, :kwoptarg).none?
    target = node.receiver
    home = home(method)
    own?(target) && !owners(target).include?(home) && !root?(home)
  end

  def findings(node, method)
    built = built(node)
    places = kept(built, method)
    return places.map { [KEPT, it] } unless places.empty?
    holder = built.parent
    found = maker(built, holder, method).select { handed_on?(node, it, holder, method) }
    return found.map { [HANDED, "#{it.receiver.source}.new"] } unless found.empty?
    !wraps?(node) && talked?(node, built, method) ? [[MSG]] : []
  end

  def handed_on?(node, found, holder, method)
    return outlives?(found, method) && !candidate?(found, method) if wraps?(node)
    !scratch?(node, holder, method)
  end

  def wraps?(node)
    parts = node.arguments
    parts.any? { !it.recursive_basic_literal? } && parts.none? { |part| part.each_node(*GLOBALS).any? { outside?(it) } }
  end

  def outside?(part)
    return false if qualifier?(part) || applied?(part)
    !part.const_type? || !part.namespace.nil? || !named?(part.short_name)
  end

  def qualifier?(part) = part.parent&.const_type? && part.parent.namespace.equal?(part)

  def applied?(part)
    holder = part.parent
    part.const_type? && type?(part) && holder&.send_type? && holder.receiver.equal?(part) && wraps?(holder)
  end

  def type?(const)
    name = const.short_name
    TYPE.match?(name) || MODULES.include?(name) || own?(const)
  end

  def named?(name) = processed_source.ast.each_node(:casgn).any? { it.short_name == name }

  def instance?(method)
    method.def_type? && !CONSTRUCTORS.include?(method.method_name) && method.each_ancestor(:sclass).none? &&
      !extended?(method)
  end

  def extended?(method)
    return true if method.each_ancestor(:any_block).any? { it.method?(:class_methods) && it.receiver.nil? }
    scope = method.each_ancestor(:class, :module).first
    return false unless scope&.module_type?
    home = RuboCop::Kata::Nesting.new(scope).qualified
    scope.identifier.short_name == :ClassMethods || extenders.include?(home)
  end

  def extenders
    @_extenders ||= [*lifted, *processed_source.ast.each_node(:send).select { extender?(it) }.flat_map { modules(it) }]
  end

  def lifted
    known = project.to_h
    known.select { |name, _| name.to_s.start_with?("#<Class:") }.values.flat_map { it.parents(known) }
  end

  def extender?(call)
    holder = call.receiver
    call.method?(:extend) && (holder.nil? || holder.type?(:self, :const) || hooked?(call))
  end

  def hooked?(call) = HOOKS.include?(call.each_ancestor(:defs).first&.method_name)

  def modules(call)
    call.arguments.select(&:const_type?).flat_map { RuboCop::Kata::Nesting.new(it).candidates(it.const_name) }
  end
end
