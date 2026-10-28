# frozen_string_literal: true

require "prism"

class RuboCop::Kata::Lineage
  MIXINS = %i[include prepend].freeze
  NESTS = [Prism::ClassNode, Prism::ModuleNode].freeze
  CONSTRUCTORS = %w[initialize initialize_copy initialize_dup initialize_clone].freeze
  CALLERS = [NilClass, Prism::SelfNode].freeze
  SINGLETON = "#<Class:%s>"

  def self.parse(source) = new(RuboCop::Kata::Kinship.parse(source).records)

  def initialize(records)
    @records = records
    @memo = {}
  end

  attr_reader :records

  def merge(other) = self.class.new(@records.merge(other.records) { |_, mine, theirs| joined(mine, theirs) })

  def ancestors(name)
    found = []
    queue = [name]
    while (current = queue.shift)
      next if found.include?(current)
      found << current
      queue.concat(parents(current))
    end
    found
  end

  def superclasses(name, found = [])
    written = @records.dig(name, :superclass)
    parent = written && resolved(*written)
    parent.nil? || found.include?(parent) ? found : superclasses(parent, [*found, parent])
  end

  def defines?(owner, method) = @records[owner]&.dig(:methods)&.key?(method) || false

  def instance?(name, method) = ancestors(name).any? { defines?(it, method) }

  def singleton?(name, method) = line(name).any? { defines?(it, "self.#{method}") } || extended?(name, method)

  def extended?(name, method)
    line(name).any? { |owner| [format(SINGLETON, owner), *concerns(owner)].any? { instance?(it, method) } }
  end

  def owners(method) = @records.keys.select { defines?(it, method) }

  def constructed(name, hooks) = @memo[[name, hooks]] ||= closure(family(name), CONSTRUCTORS | hooks)

  private

  def joined(mine, theirs)
    methods = mine[:methods].merge(theirs[:methods]) { |_, a, b| a | b }
    { parents: mine[:parents] | theirs[:parents], methods:, superclass: mine[:superclass] || theirs[:superclass] }
  end

  def line(name) = [name, *superclasses(name)]

  def concerns(name) = parents(name).map { "#{it}::ClassMethods" }.select { @records.key?(it) }

  def parents(name)
    held = @records[name]
    held ? held[:parents].map { |written, nesting| resolved(written, nesting) } : []
  end

  def resolved(written, nesting)
    return written.delete_prefix("::") if written.start_with?("::")
    candidates = nesting.reverse.map { "#{it}::#{written}" } << written
    candidates.find { @records.key?(it) } || written
  end

  def heirs(name) = @records.keys.select { it != name && ancestors(it).include?(name) }

  def family(name) = [name, *heirs(name)].flat_map { ancestors(it) }.uniq.filter_map { @records[it] }

  def closure(records, start)
    found = start
    loop do
      called = records.flat_map { |held| held[:methods].slice(*found).values.flatten }
      return found if (called - found).empty?
      found |= called
    end
  end
end
