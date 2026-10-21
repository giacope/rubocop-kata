# frozen_string_literal: true

class RuboCop::Cop::Kata::NoTypeCheck < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster

  MSG = "`%s` asks an object what it is; tell it what to do, and let polymorphism choose."
  PROTOCOL = /
    \A(
      to_\w+|each\w*|call|hash|eql\?|inspect|coerce|<=>|==|===|\[\]=?|<<|
      read|readpartial|write|rewind|close|closed\?|flush|seek|pos|eof\?|gets|getc|path|
      size|length|empty\?|keys|key\?|fetch|include\?|match\??|
      name|superclass|ancestors|arity|parameters
    )\z
  /x

  RESTRICT_ON_SEND = %i[is_a? kind_of? instance_of? respond_to?].freeze

  def on_send(node)
    method = node.each_ancestor(:def, :defs).first
    return if method && listed?("AllowedMethods", method.method_name.to_s)
    add_offense(node.loc.selector, message: format(MSG, node.method_name)) if owned?(node.first_argument, node)
  end

  private

  def owned?(probe, node)
    return false if probe.nil?
    return probe.sym_type? && message?(probe.value.to_s) if node.method?(:respond_to?)
    probe.const_type? && own_type?(probe.const_name)
  end

  def own_type?(name)
    segments = name.split("::")
    !RuboCop::Kata::Dictionary::CORE.include?(segments.first) && segments.values_at(0, -1).all? { type?(it) }
  end

  def type?(name) = local_types.include?(name) || inventory.type?(name)

  def message?(name) = !PROTOCOL.match?(name) && (local_messages.include?(name) || inventory.message?(name))

  def local_types = RuboCop::Kata::Declared.new(processed_source.ast).types

  def local_messages = processed_source.ast.each_node(:def, :defs).map { it.method_name.to_s }

  def inventory = RuboCop::Kata::Inventory.of(config.base_dir_for_path_parameters, list("OwnedPaths"))
end
