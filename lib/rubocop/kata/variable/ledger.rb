# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT
# Derived from rubocop-elegant (https://github.com/yegor256/rubocop-elegant), see LICENSE.txt

class RuboCop::Kata::Variable::Ledger
  include RuboCop::Kata::Order

  def initialize(census)
    @census = census
  end

  def pairs
    singles.reject { |assign, read| RuboCop::Kata::Variable::Boundary.new(assign, read).crossed? }.to_h
  end

  private

  def singles
    reads = @census.reads
    tainted = @census.tainted
    @census.assigns.flat_map { |name, found| tainted.include?(name) ? [] : single(found, reads.fetch(name, [])) }
  end

  def single(found, once)
    assign = found.first
    read = once.first
    found.size == 1 && once.size == 1 && precedes?(assign, read) ? [[assign, read]] : []
  end
end
