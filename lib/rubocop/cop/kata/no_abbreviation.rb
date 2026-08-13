# frozen_string_literal: true

class RuboCop::Cop::Kata::NoAbbreviation < RuboCop::Cop::Base
  MSG = "`%s` is an abbreviation; spell the word out."

  def on_lvasgn(node) = check(node)

  def on_arg(node) = check(node)

  def on_optarg(node) = check(node)

  def on_kwarg(node) = check(node)

  def on_kwoptarg(node) = check(node)

  private

  def check(node)
    name = node.name.to_s
    return unless banned?(name)
    add_offense(node.loc.name, message: format(MSG, name))
  end

  def banned?(name) = Array(cop_config["BannedNames"]).map(&:to_s).include?(name.sub(/\d+\z/, ""))
end
