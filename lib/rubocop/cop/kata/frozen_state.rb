# frozen_string_literal: true

class RuboCop::Cop::Kata::FrozenState < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Memoization

  MSG = "`%s` changes after construction; set state once in `initialize` and return a new object to change it."
  CONSTRUCTORS = %i[initialize initialize_copy initialize_dup initialize_clone].freeze

  def on_ivasgn(node)
    method = node.each_ancestor(:def, :defs).first
    return if method.nil? || class_level?(method) || builder?(method) || memoized?(node)
    add_offense(node.loc.name, message: format(MSG, node.children.first))
  end

  private

  def class_level?(method)
    method.defs_type? || method.each_ancestor(:sclass, :class, :module).first&.sclass_type?
  end

  def builder?(method)
    scope = method.each_ancestor(:class, :module, :any_block).first
    builders(scope ? scope.each_descendant(:def).to_a : [method]).include?(method.method_name)
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
