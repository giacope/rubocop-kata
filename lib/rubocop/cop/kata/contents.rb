# frozen_string_literal: true

module RuboCop::Cop::Kata::Contents
  SHARED = %i[insert delete clear update store append prepend replace pop shift unshift fill].freeze
  COLLECTIONS = %w[Array Hash Set SortedSet String Concurrent::Array Concurrent::Hash Concurrent::Map].freeze
  COPIES = %i[dup clone to_a to_h to_set Array Hash +@].freeze
  USES = %i[[] []= << each each_pair each_with_index keys values key? push].freeze

  private

  def command?(call) = SHARED.include?(call.method_name) && !collection?(call.receiver)

  def collection?(held)
    scope = held.each_ancestor(:class, :module).first || processed_source.ast
    filled?(scope, held.children.first) || scope.each_descendant(:send).any? { used?(it, held) }
  end

  def filled?(scope, name)
    scope.each_descendant(:ivasgn).any? { |held| held.children.first == name && assigned(held).any? { built?(it) } }
  end

  def used?(call, held) = call.receiver == held && USES.include?(call.method_name)

  def assigned(node) = node.parent&.type?(:or_asgn, :op_asgn) ? [node.parent.children.last] : [node.expression].compact

  def built?(value)
    return true if value.type?(:array, :hash, :str, :dstr)
    return false unless value.send_type?
    COPIES.include?(value.method_name) || (value.method?(:new) && COLLECTIONS.include?(value.receiver&.const_name))
  end
end
