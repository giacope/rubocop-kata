# frozen_string_literal: true

class RuboCop::Kata::Kit
  SOURCE = File.expand_path("../../../skills/rubocop-kata/SKILL.md", __dir__)
  MISSING = "the gem ships no skill at %s"

  def initialize(_root, io: $stdout, source: SOURCE)
    @io = io
    @source = source
  end

  def run = File.file?(@source) ? @io.print(File.read(@source)) : @io.puts(format(MISSING, @source))

  def status = File.file?(@source) ? 0 : 1
end
