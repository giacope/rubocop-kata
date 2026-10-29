# frozen_string_literal: true

class RuboCop::Cop::Kata::FailFast < RuboCop::Cop::Base
  include RuboCop::Cop::Kata::Roster
  include RuboCop::Cop::RescueNode

  MSG = "This `rescue` swallows the error and answers `%s` instead: let it raise (fail fast), or rescue " \
    "the one error you expect and answer an object that says what failed."
  LOG_MSG = "This `rescue` logs the error and swallows it: let it raise (fail fast), or rescue the one error " \
    "you expect and answer an object that says what failed."
  MODIFIER_MSG = "A `rescue` modifier catches every StandardError, bugs included: rescue the one error you " \
    "expect, or let it raise."
  LEVELS = %i[debug info warn error fatal unknown].freeze
  EXITS = %i[return next break].freeze
  EMPTY = %i[array hash].freeze
  BROAD = %w[Exception StandardError RuntimeError ScriptError NoMethodError NameError TypeError].freeze
  BUGS = %w[Exception StandardError NoMethodError].freeze
  COMPARISONS = %i[== eql? equal? <=> ===].freeze

  def on_resbody(node)
    return if escapes?(node.body) || cleanup?(node) || expected?(node)
    verdicts(node).each { add_offense(node.loc.keyword, message: it) }
  end

  private

  def verdicts(node)
    body = node.body
    lines = body&.begin_type? ? body.children : [body]
    return [LOG_MSG] if lines.all? { log?(it) }
    values = answers(lines.last)
    return swallow(node, values) if lines[0...-1].all? { log?(it) } && default?(values)
    rescue_modifier?(node) ? [MODIFIER_MSG] : []
  end

  def swallow(node, values) = answer?(node, values) ? [] : [format(MSG, values.map(&:source).fetch(0, "nil"))]

  def escapes?(body) = body&.each_node&.any? { it.retry_type? || (it.send_type? && raising?(it)) }

  def raising?(call)
    (call.receiver.nil? || call.receiver.const_type?) && listed?("RaisingMethods", call.method_name.to_s)
  end

  def cleanup?(node)
    node.each_ancestor(:resbody).any? { escapes?(it.body) } ||
      node.each_ancestor(:ensure).any? { it.children.last&.source_range&.contains?(node.source_range) }
  end

  def expected?(node)
    names = classes(node)
    names.any? && names.all? { listed?("ExpectedErrors", it) }
  end

  def classes(node) = node.exceptions.map { it.source.delete_prefix("::") }

  def answers(last) = EXITS.include?(last&.type) ? last.children.first(1) : [last].compact

  def log?(line) = line&.call_type? && LEVELS.include?(line.method_name) && line.arguments?

  def default?(values) = values.all? { it.basic_literal? || (EMPTY.include?(it.type) && it.children.empty?) }

  def answer?(node, values)
    name = node.each_ancestor(:def, :defs).first&.method_name
    COMPARISONS.include?(name) || (values.any?(&:boolean_type?) && question?(name, classes(node)))
  end

  def question?(name, names)
    return names.none? { BUGS.include?(it) } if name&.end_with?("?")
    names.any? && names.none? { BROAD.include?(it) }
  end
end
