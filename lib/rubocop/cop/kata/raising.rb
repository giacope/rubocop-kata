# frozen_string_literal: true

module RuboCop::Cop::Kata::Raising
  include RuboCop::Cop::Kata::Roster
  include RuboCop::Cop::Kata::Lending

  private

  def raises?(call)
    name = call.method_name.to_s
    target = call.receiver
    return listed?("RaisingMethods", "#{target.const_name}.#{name}") || alarm?(name, []) if target&.const_type?
    listed?("RaisingMethods", name) || ((target.nil? || target.self_type?) && alarm?(name, []))
  end

  def alarm?(name, seen)
    return true if listed?("RaisingMethods", name)
    return false if seen.include?(name)
    found = definitions(name)
    found.any? && found.all? { alarm(it, it.body)&.then { |callee| alarm?(callee, [*seen, name]) } }
  end

  def alarm(method, body)
    *before, last = body&.begin_type? ? body.children : [body]
    return unless last && before.all? { check?(it, method) }
    fence?(last) ? alarm(method, last.if_branch) : called(last)
  end

  def check?(node, method) = node.lvasgn_type? || escape?(node) || local?(node, method)

  def escape?(node) = fence?(node) && node.if_branch&.return_type? && node.if_branch.children.empty?

  def local?(node, method) = node.call_type? && node.receiver&.lvar_type? && !borrowed?(node.receiver, method)

  def fence?(node) = node.if_type? && node.else_branch.nil?

  def called(node)
    node.method_name.to_s if node.send_type? && node.receiver.nil?
  end

  def definitions(name)
    others = inventory.defining(name, processed_source.file_path.to_s)
    [*processed_source.ast.each_node(:def, :defs).select { it.method_name.to_s == name }, *others]
  end

  def inventory = RuboCop::Kata::Inventory.of(config.base_dir_for_path_parameters, list("OwnedPaths"))
end
