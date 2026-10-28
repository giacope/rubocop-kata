# frozen_string_literal: true

module RuboCop::Cop::Kata::Passage
  include RuboCop::Cop::Kata::Ownership
  include RuboCop::Cop::Kata::Lending
  include RuboCop::Cop::Kata::Ancestry
  include RuboCop::Cop::VisibilityHelp

  ANSWER_MSG = "%d keys a method answers together are an object without a name; answer an object that knows them."
  HANDED_MSG = "%d keys handed together to `%s` are an object without a name; pass an object that knows them."
  READ_MSG = "`%s` is read by its keys (%s): a hash used as an object without a name; take an object that answers them."
  MAPS = %i[map collect flat_map filter_map].freeze
  READS = %i[[] fetch dig].freeze
  BRANCHES = %i[if case case_match when in_pattern and or].freeze
  PRINTS = /\A(?:to|as)_/

  def on_def(node)
    return unless cop_config["CheckTravel"] && node.body && !protocol?(node.body) && !facing?(node)
    node.arguments.each { |argument| inspect_reads(node, argument) }
  end

  alias on_defs on_def

  private

  def inspect_reads(method, argument)
    keys = read_keys(method, argument)
    return if keys.size < 2
    add_offense(argument, message: format(READ_MSG, argument.name, keys.map { "`#{it}`" }.join(", ")))
  end

  def read_keys(method, argument)
    return [] unless LENT.include?(argument.type)
    reads = method.body.each_node(:send, :csend).select { read?(it, method, argument.name) }
    reads.map { it.first_argument.value }.uniq
  end

  def read?(call, method, name)
    READS.include?(call.method_name) && call.first_argument&.sym_type? && borrowed?(call.receiver, method, [name])
  end

  def travel(node, count)
    return unless cop_config["CheckTravel"] && count >= Integer(cop_config.fetch("TravelKeys", 2)) && symbolic?(node)
    value = carried(node)
    return format(ANSWER_MSG, count) if answering?(node, value)
    target = handed(value)
    format(HANDED_MSG, count, target) if target
  end

  def answering?(node, value)
    method = node.each_ancestor(:def, :defs).first
    method && returned?(value) && !printer?(method)
  end

  def printer?(method)
    name = method.method_name
    PRINTS.match?(name) || listed?("Printers", name.to_s) || printing?(method) || facing?(method)
  end

  def printing?(method)
    scope = method.each_ancestor(:class, :module).first
    scope && list("PrinterTypes").any? { scope.identifier.short_name.end_with?(it) }
  end

  def facing?(method) = exposed?(method, method.each_ancestor(:class, :module).first) && leaves?(frame(method))

  def symbolic?(node)
    keyed = node.pairs.size == node.children.size && node.keys.all?(&:sym_type?)
    keyed && !node.values.all?(&:recursive_basic_literal?)
  end

  def carried(node)
    value = enclosing(node)
    holder = value.parent
    return carried(holder.parent) if holder&.pair_type? && holder.value.equal?(value)
    holder&.array_type? ? carried(holder) : value
  end

  def returned?(value, seen = [])
    holder = value.parent
    return true if final?(holder, value)
    return returned?(holder, seen) if passing?(holder, value)
    followed?(holder, seen) && uses(holder).any? { returned?(it, [*seen, holder]) }
  end

  def followed?(holder, seen) = holder&.lvasgn_type? && !seen.include?(holder)

  def final?(holder, value) = holder.return_type? || (holder.type?(:def, :defs) && holder.body.equal?(value))

  def passing?(holder, value)
    return holder.children.last.equal?(value) if holder.begin_type?
    return MAPS.include?(holder.method_name) && holder.body.equal?(value) if holder.any_block_type?
    BRANCHES.include?(holder.type) && !(holder.if_type? && holder.condition.equal?(value))
  end

  def handed(value, seen = [])
    holder = value.parent
    return holder.method_name if holder&.call_type? && holder.arguments.any? { it.equal?(value) } && own_call?(holder)
    uses(holder).filter_map { handed(carried(it), [*seen, holder]) }.first if followed?(holder, seen)
  end

  def own_call?(call)
    receiver = call.receiver
    return answered?(call.method_name) if receiver.nil? || receiver.self_type?
    receiver.const_type? && defined_by?(receiver, call.method_name)
  end

  def defined_by?(receiver, name)
    owner = owners(receiver).first
    name == :new ? project.instance?(owner, "initialize") : project.singleton?(owner, name.to_s)
  end

  def uses(assignment)
    name = assignment.name
    scope = assignment.each_ancestor(:def, :defs).first || processed_source.ast
    scope.each_node(:lvar).select { it.children.first == name }
  end
end
