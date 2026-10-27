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
  RELEASES = %i[close close_read close_write shutdown kill terminate disconnect finish unlink].freeze
  COMPARISONS = %i[== eql? equal? <=> ===].freeze

  def on_resbody(node)
    return if escapes?(node.body) || cleanup?(node) || expected?(node)
    message = verdict(node)
    add_offense(node.loc.keyword, message:) if message
  end

  private

  def verdict(node)
    lines = statements(node.body)
    return LOG_MSG if lines.all? { log?(it) }
    value = answer(lines.last)
    return swallow(node, value) if lines[0...-1].all? { log?(it) } && default?(value)
    MODIFIER_MSG if rescue_modifier?(node)
  end

  def swallow(node, value) = answer?(node, value) ? nil : format(MSG, value&.source || "nil")

  def escapes?(body) = body&.each_node&.any? { it.retry_type? || (it.send_type? && raising?(it)) }

  def raising?(call)
    (call.receiver.nil? || call.receiver.const_type?) && listed?("RaisingMethods", call.method_name.to_s)
  end

  def cleanup?(node)
    node.each_ancestor(:resbody).any? { escapes?(it.body) } || release?(node.parent.body) ||
      node.each_ancestor(:ensure).any? { it.children.last&.source_range&.contains?(node.source_range) }
  end

  def release?(body) = statements(body).all? { it&.send_type? && RELEASES.include?(it.method_name) }

  def expected?(node)
    names = classes(node)
    names.any? && names.all? { listed?("ExpectedErrors", it) }
  end

  def classes(node) = node.exceptions.map { it.source.delete_prefix("::") }

  def statements(body) = body&.begin_type? ? body.children : [body]

  def answer(last) = EXITS.include?(last&.type) ? last.children.first : last

  def log?(line) = line&.send_type? && LEVELS.include?(line.method_name) && line.arguments?

  def default?(value) = value.nil? || value.basic_literal? || (EMPTY.include?(value.type) && value.children.empty?)

  def answer?(node, value)
    name = node.each_ancestor(:def, :defs).first&.method_name
    COMPARISONS.include?(name) || (value&.boolean_type? && question?(name, classes(node)))
  end

  def question?(name, names)
    return names.none? { BUGS.include?(it) } if name&.end_with?("?")
    names.any? && names.none? { BROAD.include?(it) }
  end
end
