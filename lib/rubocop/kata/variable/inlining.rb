# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT
# Derived from rubocop-elegant (https://github.com/yegor256/rubocop-elegant), see LICENSE.txt

class RuboCop::Kata::Variable::Inlining
  PRIMARY = %i[
    int float str sym dstr dsym xstr true false nil array hash regexp
    lvar ivar cvar gvar const self nth_ref back_ref
  ].freeze

  def initialize(rhs, read)
    @rhs = rhs
    @read = read
  end

  def range = pairs.fetch(0, @read).source_range

  def text = pairs.empty? ? value : "#{pairs.first.key.source}: #{value}"

  def faithful? = !(guarded? && receiver?)

  private

  def pairs
    parent = @read.parent
    parent.pair_type? && parent.value_omission? ? [parent] : []
  end

  def value = wrap? ? "(#{@rhs.source})" : @rhs.source

  def wrap? = !primary? || (@rhs.source.start_with?("{") && bare?)

  def primary?
    return true if PRIMARY.include?(@rhs.type)
    return @rhs.parenthesized? || @rhs.arguments.empty? if @rhs.call_type?
    @rhs.begin_type? && @rhs.children.size == 1
  end

  def guarded?
    link = @rhs
    link = link.receiver while link&.send_type?
    link&.csend_type?
  end

  def receiver?
    parent = @read.parent
    parent&.send_type? && parent.receiver.equal?(@read)
  end

  def bare?
    parent = @read.parent
    parent.call_type? && !parent.parenthesized? && parent.arguments.include?(@read)
  end
end
