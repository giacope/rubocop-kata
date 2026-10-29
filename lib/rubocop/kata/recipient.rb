# frozen_string_literal: true

class RuboCop::Kata::Recipient
  def initialize(call, root, inheritance)
    @call = call
    @root = root
    @inheritance = inheritance
  end

  def answers?
    caller = @call.each_ancestor(:def, :defs).first
    return false unless caller
    home = place(caller)
    local?(home) || inherited?(*home)
  end

  private

  def local?(home)
    (home.first || @root).each_descendant(:def, :defs).any? { it.method?(@call.method_name) && place(it) == home }
  end

  def inherited?(scope, singleton)
    return false unless scope
    name = RuboCop::Kata::Nesting.new(scope).qualified
    method = @call.method_name.to_s
    singleton ? @inheritance.singleton?(name, method) : @inheritance.instance?(name, method)
  end

  def place(method)
    scope = method.each_ancestor(:class, :module, :sclass).first
    return [scope, method.defs_type?] unless scope&.sclass_type?
    [scope.each_ancestor(:class, :module).first, true]
  end
end
