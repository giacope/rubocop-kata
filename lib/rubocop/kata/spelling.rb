# frozen_string_literal: true

class RuboCop::Kata::Spelling
  VARIANTS = [
    [/our/, "or"],
    [/is(e|ed|es|ing|ation|ations|er|ers|able)\z/, 'iz\1'],
    [/isations?\z/, "ize"],
    [/ys(e|ed|es|ing|er|ers)\z/, 'yz\1'],
    [/tre(s|d)?\z/, 'ter\1'],
    [/tr(ed|ing)\z/, 'ter\1'],
    [/ence(s)?\z/, 'ense\1'],
    [/ll(ed|ing|er|ers|or|ors)\z/, 'l\1'],
    [/ogue(s)?\z/, 'og\1'],
    [/mme(s)?\z/, 'm\1'],
    [/ae/, "e"],
    [/oe/, "e"]
  ].freeze

  def initialize(form)
    @form = form
  end

  def american = VARIANTS.map { |pattern, swap| @form.sub(pattern, swap) }
end
