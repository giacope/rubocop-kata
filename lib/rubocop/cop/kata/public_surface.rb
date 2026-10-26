# frozen_string_literal: true

class RuboCop::Cop::Kata::PublicSurface < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster
  include RuboCop::Cop::Kata::Exposure
  include RuboCop::Cop::Kata::Census

  MSG = "`%s` exposes %d public methods (%s); keep at most %d, and move the rest to an object of their own."
  MINTS = { attr_reader: [""], attr: [""], attr_writer: ["="], attr_accessor: ["", "="] }.freeze

  def on_class(node)
    body = statements(node)
    defined = body.flat_map { definitions(it) }.reject { hidden?(it) }.map(&:method_name)
    minted = body.select { minting?(it) }.flat_map { names(it) }
    census(node, (defined + minted).uniq.reject { protocol?(it) }, MSG)
  end

  private

  def definitions(statement)
    return [statement] if statement.def_type?
    statement.send_type? && statement.receiver.nil? ? statement.arguments.select(&:def_type?) : []
  end

  def minting?(statement)
    statement.send_type? && statement.receiver.nil? && MINTS.key?(statement.method_name) && !hidden?(statement)
  end

  def names(call)
    fields = call.arguments.select(&:sym_type?).map(&:value)
    MINTS.fetch(call.method_name).flat_map { |suffix| fields.map { :"#{it}#{suffix}" } }
  end

  def protocol?(name)
    text = name.to_s
    listed?("Protocols", text) || list("AllowedPatterns").any? { Regexp.new(it).match?(text) }
  end
end
