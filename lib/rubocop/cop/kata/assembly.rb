# frozen_string_literal: true

module RuboCop::Cop::Kata::Assembly
  include RuboCop::Cop::Kata::Roster
  include RuboCop::Cop::Kata::Ancestry

  BODIES = %i[class module any_block].freeze
  SEAM = "take one in the constructor, with this `new` as the parameter's default."
  BUILT = "`%s` cannot take one in a constructor (a framework builds it past `initialize`, or it is mixed in): " \
    "take one as a parameter of `%s`, with this `new` as its default, or build it where `%s` is used."

  private

  def scope(method) = method.each_ancestor(:class, :module).first

  def home(method) = scope(method)&.then { RuboCop::Kata::Nesting.new(it).qualified }.to_s

  def seam(method)
    home = home(method)
    return SEAM unless mixin?(method) || project.ancestors(home).intersect?(list("BuiltSuperclasses"))
    format(BUILT, home, method.method_name, home)
  end

  def mixin?(method) = method.each_ancestor(*BODIES).first&.module_type?

  def root?(home)
    project.ancestors(home).intersect?(list("RootSuperclasses")) || hooks(home).intersect?(list("RootHooks"))
  end

  def hooks(home)
    @_hooks ||= [*inventory.hooks, *RuboCop::Kata::Kinship.parse(processed_source.raw_source).hooks]
    @_hooks.filter_map { |name, hook| hook if name == home }
  end
end
