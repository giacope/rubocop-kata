# frozen_string_literal: true

class RuboCop::Kata::Kit
  SOURCE = File.expand_path("../../../skills/rubocop-kata/SKILL.md", __dir__)
  MISSING = "the gem ships no skill at %s"

  def initialize(_root, io: $stdout)
    @io = io
  end

  def run
    return missing unless File.file?(SOURCE)
    @io.print(File.read(SOURCE))
    0
  end

  private

  def missing
    @io.puts(format(MISSING, SOURCE))
    1
  end
end
