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

  def range = pair.nil? ? @read.source_range : pair.source_range

  def text = pair.nil? ? value : "#{pair.children.first.source}: #{value}"

  private

  def pair
    parent = @read.parent
    parent if parent.pair_type? && parent.value_omission?
  end

  def value = wrap? ? "(#{@rhs.source})" : @rhs.source

  def wrap? = !primary? || (@rhs.source.start_with?("{") && bare?)

  def primary?
    return true if PRIMARY.include?(@rhs.type)
    return !@rhs.loc.begin.nil? || @rhs.arguments.empty? if @rhs.send_type? || @rhs.csend_type?
    @rhs.begin_type? && @rhs.children.size == 1
  end

  def bare?
    parent = @read.parent
    return false if parent.nil? || !(parent.send_type? || parent.csend_type?)
    parent.loc.begin.nil? && parent.arguments.include?(@read)
  end
end
