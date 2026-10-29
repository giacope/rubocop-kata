# frozen_string_literal: true

module RuboCop::Cop::Kata::Destination
  include RuboCop::Cop::Kata::Blocks

  COMMAND = "command"
  URL = "URL"
  PLACES = %i[base chdir].freeze
  AIMS = %i[url].freeze

  private

  def targets(node, noun)
    return node.arguments if noun == COMMAND
    leading = node.arguments.first(1)
    return [*leading, *keyed(node, PLACES)] unless noun == URL
    aimed = [*leading.reject(&:hash_type?), *keyed(node, AIMS)]
    aimed.empty? ? requests(node).flat_map { it.arguments.first(1) } : aimed
  end

  def keyed(node, keys)
    pairs = node.arguments.select(&:hash_type?).flat_map(&:pairs)
    pairs.select { it.key.sym_type? && keys.include?(it.key.value) }.map(&:value)
  end

  def requests(node)
    built = blocked(node)
    holder = built.parent
    return [holder] if holder&.send_type? && holder.receiver.equal?(built)
    holder&.lvasgn_type? ? sent(holder) : []
  end

  def sent(assignment)
    scope = assignment.each_ancestor(:def, :defs, :class, :module, :sclass).first
    scope.each_node(:send).select { held?(it.receiver, assignment.name) }
  end

  def held?(receiver, name) = receiver&.lvar_type? && receiver.children.first == name
end
