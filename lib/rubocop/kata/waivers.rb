# frozen_string_literal: true

class RuboCop::Kata::Waivers
  WAIVER = "%s:%d: disables `%s` — %s"
  BARE = "no reason given"
  TALLY = "%d inline disable%s, %d without a reason"

  def initialize(parsed)
    @parsed = parsed
  end

  def lines = listed.map { |path, line, cops, reason| format(WAIVER, path, line, cops, reason.empty? ? BARE : reason) }

  def tally
    return [] if listed.empty?
    [format(TALLY, listed.size, listed.one? ? "" : "s", bare)]
  end

  def bare = listed.count { it.last.empty? }

  private

  def listed
    @_listed ||=
      @parsed.flat_map do |path, source|
        source.comments.map { RuboCop::Kata::Waiver.new(it) }.select(&:disabling?)
          .map { [path, it.line, it.cops.join("`, `"), it.reason] }
      end
  end
end
