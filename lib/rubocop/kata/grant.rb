# frozen_string_literal: true

class RuboCop::Kata::Grant
  ONE = %i[def_delegator def_instance_delegator def_single_delegator].freeze
  MANY = %i[def_delegators def_instance_delegators def_single_delegators].freeze
  SINGLE = %i[def_single_delegator def_single_delegators].freeze
  READERS = %i[attr attr_reader attr_accessor].freeze
  WRITERS = %i[attr_writer attr_accessor].freeze

  def initialize(call)
    @call = call
  end

  def names
    found = granted
    SINGLE.include?(@call.name) ? found.map { "self.#{it}" } : found
  end

  private

  def granted
    case @call.name
    when *ONE then words.drop(1).last(1)
    when *MANY then words.drop(1)
    when :delegate then delegated
    when :alias_method then words.first(1)
    else attributes
    end
  end

  def attributes
    found = words
    [*(READERS.include?(@call.name) ? found : []), *(WRITERS.include?(@call.name) ? found.map { "#{it}=" } : [])]
  end

  def delegated
    prefix = options["prefix"]
    stem = prefix&.slice == "true" ? spelled(options["to"]).to_s.delete_prefix("@") : spelled(prefix)
    words.map { stem.to_s.empty? ? it : "#{stem}_#{it}" }
  end

  def words = arguments.filter_map { spelled(it) }

  def options
    pairs = arguments.select { it.respond_to?(:elements) }.flat_map(&:elements).select { it.respond_to?(:key) }
    pairs.to_h { [spelled(it.key), it.value] }
  end

  def spelled(node) = node.respond_to?(:unescaped) ? node.unescaped : nil

  def arguments = Array(@call.arguments&.arguments)
end
