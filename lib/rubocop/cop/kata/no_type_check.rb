# frozen_string_literal: true

class RuboCop::Cop::Kata::NoTypeCheck < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster
  include RuboCop::Cop::Kata::Ownership

  MSG = "`%s` asks an object what it is; tell it what to do, and let polymorphism choose."
  PROTOCOL = /
    \A(
      to_\w+|each\w*|call|hash|eql\?|inspect|coerce|<=>|==|===|\[\]=?|<<|
      read|readpartial|write|rewind|close|closed\?|flush|seek|pos|eof\?|gets|getc|path|
      size|length|empty\?|keys|key\?|fetch|include\?|match\??|
      name|superclass|ancestors|arity|parameters
    )\z
  /x
  PROBES = %i[is_a? kind_of? instance_of?].freeze
  EQUALITIES = %i[== != eql? equal?].freeze
  LITERALS = %i[str dstr array hash int float sym dsym regexp].freeze

  RESTRICT_ON_SEND = [*PROBES, :respond_to?, :===, *EQUALITIES].freeze

  def_node_matcher :class_of?, "(send _ :class)"
  def_node_matcher :class_name?, "(send (send _ :class) :name)"

  def on_send(node)
    label = probe(node)
    report(node, node.loc.selector, label) if label
  end

  def on_case(node)
    tested = node.when_branches.flat_map(&:conditions)
    report(node, node.loc.keyword, "case … when") if node.condition && tested.any? { own?(it) }
  end

  def on_case_match(node)
    tested =
      node.in_pattern_branches.flat_map do |branch|
        branch.pattern.each_node(:const).reject do
          it.parent&.const_type?
        end
      end
    report(node, node.loc.keyword, "case … in") if tested.any? { own?(it) }
  end

  private

  def report(node, range, label)
    method = node.each_ancestor(:def, :defs).first
    add_offense(range, message: format(MSG, label)) unless method && listed?("AllowedMethods", method.method_name.to_s)
  end

  def probe(node)
    name = node.method_name
    return equality(node) if EQUALITIES.include?(name)
    name if probed?(node, name)
  end

  def probed?(node, name)
    probe = node.first_argument
    return own?(probe) if PROBES.include?(name)
    return own?(node.receiver) if name == :===
    probe&.sym_type? && !stranger?(node.receiver) && message?(probe.value.to_s, node.arguments[1]&.true_type?)
  end

  def stranger?(receiver) = LITERALS.include?(receiver&.type) || (receiver&.const_type? && !own?(receiver))

  def equality(node)
    sides = [node.receiver, node.first_argument]
    return "class #{node.method_name}" if sides.any? { class_of?(it) } && sides.any? { own?(it) }
    named = sides.find { it&.str_type? }
    "class.name #{node.method_name}" if named && sides.any? { class_name?(it) } && own_name?(named.value, named)
  end

  def message?(name, hidden)
    return false if PROTOCOL.match?(name) || RuboCop::Kata::Protocols.new(list("Protocols")).include?(name)
    [*local_owners(name, hidden), *inventory.owners(name, hidden:)].any? { it && !foreign?(it) }
  end

  def local_owners(name, hidden)
    local_messages.filter_map { |owner, defined, shown| owner if defined == name && (hidden || shown == :public) }
  end

  def local_messages = @_local_messages ||= RuboCop::Kata::Messages.new(processed_source.raw_source).records
end
