# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT
# Derived from rubocop-elegant (https://github.com/yegor256/rubocop-elegant), see LICENSE.txt

class RuboCop::Kata::Variable::Gap
  PURE = %i[
    int float rational complex str sym true false nil array hash regexp regopt
    irange erange lvar self pair begin
  ].freeze

  def initialize(movable)
    @movable = movable
    @memo = {}
  end

  def crossed?(assign, read)
    @memo[assign] = scan?(assign, read) unless @memo.key?(assign)
    @memo[assign]
  end

  private

  def scan?(assign, read)
    steps(assign, read).any? do |child, parent|
      before(parent, child, assign).any? { !deferred?(it, read) }
    end
  end

  def steps(assign, read)
    lineage = read.each_ancestor.to_a
    [read, *lineage[..(lineage.index { it.equal?(assign.parent) })]].each_cons(2)
  end

  def before(parent, child, assign)
    kids = parent.children
    stop = kids.index { it.equal?(child) }
    return [] if stop.nil?
    kids[(parent.equal?(assign.parent) ? kids.index { it.equal?(assign) } + 1 : 0)...stop]
  end

  def deferred?(node, read)
    return true if pure?(node)
    twin = @movable[node]
    !twin.nil? && twin.source_range.begin_pos >= read.source_range.begin_pos && !crossed?(node, twin)
  end

  def pure?(node)
    return true unless node.is_a?(RuboCop::AST::Node)
    PURE.include?(node.type) && node.each_child_node.all? { pure?(it) }
  end
end
