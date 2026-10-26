# frozen_string_literal: true

module RuboCop::Cop::Kata::Answer
  VALUES = %i[
    str dstr sym dsym int float rational complex array hash regexp true false const
    ivar lvar cvar gvar irange erange
  ].freeze
  QUERIES = %i[
    + - * / % ** == != < > <= >= <=> & | ^ ! -@ +@ ~
    [] count detect dig downcase fetch filter_map find first flat_map format join keys last length map max
    merge min new reject select size sort sort_by split strip sum to_a to_h to_i to_s to_sym upcase values
  ].freeze

  private

  def value?(node) = VALUES.include?(node.type) || (node.send_type? && answer?(node))

  def answer?(call) = QUERIES.include?(call.method_name) || call.predicate_method?

  def tail(body) = body.begin_type? ? body.children.fetch(-1) : body
end
