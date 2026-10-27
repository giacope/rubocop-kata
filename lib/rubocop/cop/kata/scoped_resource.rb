# frozen_string_literal: true

class RuboCop::Cop::Kata::ScopedResource < RuboCop::Cop::Base
  MSG = "`%s` is released by `%s` outside an `ensure`: an exception between them never releases it. Hold it " \
    "for a block (`synchronize { ... }`, `File.open(path) { ... }`) or release it in `ensure`."
  PAIRS = { lock: :unlock, acquire: :release, checkout: :checkin, lock!: :unlock! }.freeze
  RELEASES = %i[close disconnect release shutdown].freeze
  COVERED = %w[File Tempfile].freeze

  def on_def(node) = check(node)

  def on_defs(node) = check(node)

  private

  def check(method)
    calls = method.each_descendant(:send, :csend, :yield, :super, :zsuper).to_a
    calls.select(&:call_type?).each { held(it, calls) }
    method.each_descendant(:lvasgn).each { opened(it, calls) }
  end

  def held(call, calls)
    undo = PAIRS[call.method_name]
    return unless undo && call.receiver
    report(call, calls.select { it.call_type? && it.method?(undo) && same?(it.receiver, call.receiver) }, calls)
  end

  def opened(assignment, calls)
    value = assignment.expression
    return unless value&.call_type? && !covered?(value)
    report(value, calls.select { closing?(it, assignment.name) }, calls)
  end

  def same?(receiver, other) = receiver&.source == other.source

  def closing?(call, name) = call.call_type? && RELEASES.include?(call.method_name) && call.receiver == s(:lvar, name)

  def covered?(value) = value.method?(:open) && COVERED.include?(value.receiver&.const_name)

  def guarded?(release)
    [release, *release.each_ancestor].each_cons(2).any? do |inner, outer|
      outer.resbody_type? || (outer.ensure_type? && outer.children.last.equal?(inner))
    end
  end

  def between?(acquired, release, calls)
    gap = acquired.source_range.end_pos...release.source_range.begin_pos
    calls.any? { gap.cover?(it.source_range.begin_pos) }
  end

  def report(acquired, releases, calls)
    release = releases.find { !guarded?(it) && between?(acquired, it, calls) }
    add_offense(acquired, message: format(MSG, acquired.source, release.source)) if release
  end
end
