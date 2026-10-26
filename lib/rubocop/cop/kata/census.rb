# frozen_string_literal: true

module RuboCop::Cop::Kata::Census
  include RuboCop::Cop::Kata::Tally

  private

  def census(node, found, message)
    most = cop_config.fetch("Max", 4)
    return if found.size <= most
    names = joined(found.map { "`#{it}`" })
    add_offense(node.loc.name, message: format(message, node.identifier.short_name, found.size, names, most))
  end
end
