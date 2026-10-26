# frozen_string_literal: true

class RuboCop::Cop::Kata::PublicSurface < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster
  include RuboCop::Cop::Kata::Exposure
  include RuboCop::Cop::Kata::Tally

  MSG = "`%s` exposes %d public methods (%s); keep at most %d, and move the rest to an object of their own."
  MINTS = { attr_reader: [""], attr: [""], attr_writer: ["="], attr_accessor: ["", "="] }.freeze

  def on_class(node)
    found = surface(node)
    most = cop_config.fetch("Max", 4)
    return if found.size <= most
    add_offense(node.loc.name, message: format(MSG, node.identifier.short_name, found.size, listed(found), most))
  end

  private

  def surface(node) = (defined(node) + minted(node)).uniq.reject { protocol?(it) }

  def defined(node) = statements(node).flat_map { definitions(it) }.reject { hidden?(it) }.map(&:method_name)

  def definitions(statement)
    return [statement] if statement.def_type?
    statement.send_type? && statement.receiver.nil? ? statement.arguments.select(&:def_type?) : []
  end

  def minted(node)
    statements(node).select { it.send_type? && it.receiver.nil? && MINTS.key?(it.method_name) && !hidden?(it) }
      .flat_map { |call| names(call) }
  end

  def names(call)
    fields = call.arguments.select(&:sym_type?).map(&:value)
    MINTS.fetch(call.method_name).flat_map { |suffix| fields.map { :"#{it}#{suffix}" } }
  end

  def protocol?(name)
    text = name.to_s
    listed?("Protocols", text) || list("AllowedPatterns").any? { Regexp.new(it).match?(text) }
  end

  def listed(found) = joined(found.map { "`#{it}`" })
end
