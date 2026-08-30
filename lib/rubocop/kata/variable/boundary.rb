# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT
# Derived from rubocop-elegant (https://github.com/yegor256/rubocop-elegant), see LICENSE.txt

class RuboCop::Kata::Variable::Boundary
  LOOPS = %i[block numblock while until while_post until_post for].freeze
  FIRSTS = %i[if case case_match and or].freeze
  HOISTS = %i[rescue resbody ensure].freeze

  def initialize(assign, read)
    @assign = assign
    @read = read
  end

  def crossed?
    return true unless @read.each_ancestor.any? { it.equal?(@assign.parent) }
    steps.any? { |child, parent| blocks?(child, parent) }
  end

  private

  def steps
    lineage = @read.each_ancestor.take_while { !it.equal?(@assign.parent) }
    [@read, *lineage].each_cons(2)
  end

  def blocks?(child, parent)
    return true if LOOPS.include?(parent.type) || HOISTS.include?(parent.type)
    FIRSTS.include?(parent.type) && !parent.children.first.equal?(child)
  end
end
