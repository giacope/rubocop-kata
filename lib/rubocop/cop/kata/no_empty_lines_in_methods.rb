# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT
# Derived from rubocop-elegant (https://github.com/yegor256/rubocop-elegant), see LICENSE.txt

class RuboCop::Cop::Kata::NoEmptyLinesInMethods < RuboCop::Cop::Base
  extend RuboCop::Cop::AutoCorrector
  include RuboCop::Cop::Kata::Verbatim

  MSG = "Empty line inside method body is not allowed"

  def on_new_investigation
    ast = processed_source.ast
    return unless ast
    bodies = ast.each_node(:def, :defs).filter_map(&:body).reject(&:single_line?)
    report(bodies.flat_map { (it.first_line..it.last_line).to_a }.to_set - verbatim(ast))
  end
end
