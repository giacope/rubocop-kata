# frozen_string_literal: true

module RuboCop::Cop::Kata::Structure
  extend RuboCop::AST::NodePattern::Macros

  STRUCT = /\bStruct\.new\(([^)]*)\)/
  MEMBER = /:(\w+)/

  def_node_matcher :struct?, "(send (const {nil? cbase} :Struct) :new ...)"

  private

  def members = @_members ||= [*written_members, *project_members]

  def written_members
    built = processed_source.ast.each_node(:send).select { struct?(it) }
    built.map { |call| call.arguments.select(&:sym_type?).map(&:value) }
  end

  def project_members
    sources.texts.flat_map { it.scan(STRUCT) }.map { |(listed)| listed.scan(MEMBER).flatten.map(&:to_sym) }
  end
end
