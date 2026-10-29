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
  SIGNALS = %w[Errno::EPERM].freeze

  def_node_matcher :signal?, "(send _ :kill _ _ ...)"

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
    names.any? && names.all? { listed?("ExpectedErrors", it) || (SIGNALS.include?(it) && signaling?(node)) }
  end

  def signaling?(node)
    body = node.parent.body
    lines = body&.begin_type? ? body.children : [body]
    lines.all? { signal?(it) }
  end

  def classes(node) = node.exceptions.map { it.source.delete_prefix("::") }

  def answers(last) = EXITS.include?(last&.type) ? last.children.first(1) : [last].compact

  def log?(line) = level?(line) && !answered_here?(line)

  def level?(line) = line&.call_type? && LEVELS.include?(line.method_name) && line.arguments?

  def answered_here?(call)
    holder = call.receiver
    found = holder.nil? || holder.self_type? ? definitions(call) : []
    found.any? && found.none? { logs?(it.body) }
  end

  def definitions(call)
    scope = call.each_ancestor(:class, :module).first
    found = scope ? scope.each_descendant(:def).select { it.method?(call.method_name) } : []
    found.select { it.each_ancestor(:class, :module).first.equal?(scope) }
  end

  def logs?(body)
    lines = body&.begin_type? ? body.children : [body]
    lines.any? { it.nil? || level?(it) }
  end

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
