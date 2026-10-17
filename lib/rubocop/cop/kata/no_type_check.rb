# frozen_string_literal: true

class RuboCop::Cop::Kata::NoTypeCheck < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster

  MSG = "`%s` asks an object what it is; tell it what to do, and let polymorphism choose."

  RESTRICT_ON_SEND = %i[is_a? kind_of? instance_of? respond_to?].freeze

  def on_send(node)
    method = node.each_ancestor(:def, :defs).first
    return if method && listed?("AllowedMethods", method.method_name.to_s)
    add_offense(node.loc.selector, message: format(MSG, node.method_name))
  end
end
