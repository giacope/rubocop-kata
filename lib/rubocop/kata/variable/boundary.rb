# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT
# Derived from rubocop-elegant (https://github.com/yegor256/rubocop-elegant), see LICENSE.txt

class RuboCop::Kata::Variable::Boundary
  LOOPS = %i[block numblock while until while_post until_post for].freeze
  FIRSTS = %i[if case case_match and or or_asgn and_asgn].freeze
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
    type = parent.type
    return true if LOOPS.include?(type) || HOISTS.include?(type)
    return !parent.receiver.equal?(child) && guarded?(parent) if parent.call_type?
    FIRSTS.include?(type) && !parent.children.first.equal?(child)
  end

  def guarded?(call)
    link = call
    link = link.receiver while link&.send_type?
    link&.csend_type?
  end
end
