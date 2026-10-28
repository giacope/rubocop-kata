# frozen_string_literal: true

module RuboCop::Cop::Kata::Raising
  include RuboCop::Cop::Kata::Roster

  private

  def raises?(call)
    name = call.method_name.to_s
    listed?("RaisingMethods", name) || ((call.receiver.nil? || call.receiver.self_type?) && alarm?(name, []))
  end

  def alarm?(name, seen)
    return true if listed?("RaisingMethods", name)
    return false if seen.include?(name)
    found = definitions(name)
    found.any? && found.all? { alarm(it.body)&.then { |callee| alarm?(callee, [*seen, name]) } }
  end

  def alarm(body)
    *before, last = body&.begin_type? ? body.children : [body]
    return unless last && before.all?(&:lvasgn_type?)
    fence?(last) ? alarm(last.if_branch) : called(last)
  end

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
