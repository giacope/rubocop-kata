# frozen_string_literal: true

class RuboCop::Kata::Lineage
  CONSTRUCTORS = %w[initialize initialize_copy initialize_dup initialize_clone].freeze

  def self.parse(source) = new(RuboCop::Kata::Kinship.parse(source).records)

  def initialize(records)
    @records = records
    @memo = {}
  end

  def [](name) = @records.fetch(name) { RuboCop::Kata::Kin.new }

  def to_h = @records

  def merge(other) = self.class.new(@records.merge(other.to_h) { |_, mine, theirs| mine + theirs })

  def ancestors(name)
    found = []
    queue = [name]
    while (current = queue.shift)
      next if found.include?(current)
      found << current
      queue.concat(self[current].parents(@records))
    end
    found
  end

  def superclasses(name, found = [])
    parent = self[name].superclass(@records).first
    parent.nil? || found.include?(parent) ? found : superclasses(parent, [*found, parent])
  end

  def constructed(name, hooks) = @memo[[name, hooks]] ||= closure(family(name), CONSTRUCTORS | hooks)

  private

  def heirs(name) = @records.keys.select { it != name && ancestors(it).include?(name) }

  def family(name) = [name, *heirs(name)].flat_map { ancestors(it) }.uniq.filter_map { @records[it] }

  def closure(kins, start) = RuboCop::Kata::Closure.new(start) { |found| kins.flat_map { it.calls(found) } }.to_a
end
