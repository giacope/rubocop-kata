# frozen_string_literal: true

class RuboCop::Kata::Variable::Label
  PLAIN = %i[int float rational complex str sym true false nil lvar ivar cvar gvar const self].freeze
  GENERIC = %w[result results value values data out output item thing object].freeze
  VARIABLES = %i[lvar ivar cvar gvar].freeze

  def initialize(assign, sorbet:)
    @assign = assign
    @sorbet = sorbet
  end

  def explains?
    value = @assign.expression
    value = RuboCop::Kata::Annotation.new(value).value if @sorbet
    return true if spread?(value)
    return false if PLAIN.include?(value.type)
    said = told(value)
    @assign.name.to_s.split("_").any? { |word| meaningful?(word) && !said.include?(word) }
  end

  private

  def spread?(value) = value.multiline? || value.each_node(:str, :dstr, :xstr).any?(&:heredoc?)

  def meaningful?(word) = word.sub(/\d+\z/, "").length > 1 && !GENERIC.include?(word)

  def told(value) = value.each_node.flat_map { spoken(it) }.flat_map { it.split("_") }.to_set

  def spoken(node)
    return [node.method_name.to_s.delete("?!=")] if node.call_type?
    return [node.children.first.to_s.delete("@$")] if VARIABLES.include?(node.type)
    return [node.short_name.to_s.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase] if node.const_type?
    []
  end
end
