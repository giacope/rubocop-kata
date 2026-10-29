# frozen_string_literal: true

class RuboCop::Kata::Inheritance
  def initialize(lineage)
    @lineage = lineage
  end

  def instance?(name, method) = @lineage.ancestors(name).any? { @lineage[it].defines?(method) }

  def singleton?(name, method) = line(name).any? { @lineage[it].defines?("self.#{method}") } || extended?(name, method)

  def extended?(name, method)
    line(name).any? { |owner| ["#<Class:#{owner}>", *concerns(owner)].any? { instance?(it, method) } }
  end

  def owners(method) = @lineage.to_h.filter_map { |name, kin| name if kin.defines?(method) }

  private

  def line(name) = [name, *@lineage.superclasses(name)]

  def concerns(name)
    known = @lineage.to_h
    @lineage[name].parents(known).map { "#{it}::ClassMethods" }.select { known.key?(it) }
  end
end
