# frozen_string_literal: true

require "prism"

class RuboCop::Kata::Lineage
  MIXINS = %i[include prepend].freeze
  NESTS = [Prism::ClassNode, Prism::ModuleNode].freeze
  CONSTRUCTORS = %w[initialize initialize_copy initialize_dup initialize_clone].freeze
  CALLERS = [NilClass, Prism::SelfNode].freeze

  def self.parse(source) = new(RuboCop::Kata::Kinship.new(Prism.parse(source).value).records)

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

  def defines?(owner, method) = @records[owner]&.dig(:methods)&.key?(method) || false

  def owners(method) = @records.keys.select { defines?(it, method) }

  def constructed(name, hooks) = @memo[[name, hooks]] ||= closure(family(name), CONSTRUCTORS | hooks)

  private

  def joined(mine, theirs)
    { parents: mine[:parents] | theirs[:parents], methods: mine[:methods].merge(theirs[:methods]) { |_, a, b| a | b } }
  end

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
