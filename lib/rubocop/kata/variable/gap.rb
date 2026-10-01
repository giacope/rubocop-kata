# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT
# Derived from rubocop-elegant (https://github.com/yegor256/rubocop-elegant), see LICENSE.txt

class RuboCop::Kata::Variable::Gap
  PURE = %i[
    int float rational complex str sym true false nil array hash regexp regopt
    irange erange lvar self pair begin
  ].freeze

  def initialize(pairs, movable)
    @pairs = pairs
    @movable = movable
    @memo = {}
  end

  def crossed?(assign)
    @memo[assign] = scan?(assign) unless @memo.key?(assign)
    @memo[assign]
  end

  private

  def scan?(assign)
    read = @pairs.fetch(assign)
    steps(assign, read).any? do |child, parent|
      before(parent, child, assign).any? { !deferred?(it, read) }
    end
  end

  def steps(assign, read)
    lineage = read.each_ancestor.to_a
    [read, *lineage[..(lineage.index { it.equal?(assign.parent) })]].each_cons(2)
  end

  def before(parent, child, assign)
    start = parent.equal?(assign.parent) ? assign.sibling_index + 1 : 0
    parent.children[start...child.sibling_index]
  end

  def deferred?(node, read) = pure?(node) || (@movable.key?(node) && later?(node, read))

  def later?(node, read)
    @pairs.fetch(node).source_range.begin_pos >= read.source_range.begin_pos && !crossed?(node)
  end

  def pure?(node)
    return true unless node.is_a?(RuboCop::AST::Node)
    PURE.include?(node.type) && node.each_child_node.all? { pure?(it) }
  end
end
