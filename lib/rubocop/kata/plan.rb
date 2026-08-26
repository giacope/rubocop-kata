# frozen_string_literal: true

require "json"
require "tempfile"

class RuboCop::Kata::Plan
  STAGES = {
    "structure" => %w[
      Kata/ConstructorDiscipline Kata/NoClassMethodLogic Kata/NoHashAsObject
      Kata/NoBooleanFlag Kata/IoDiscipline Kata/ClockDiscipline Kata/EnvDiscipline
    ],
    "naming" => %w[
      Kata/RealWords Kata/GoodMethodName Kata/GoodVariableName Kata/GoodClassName
      Kata/GoodModuleName Kata/BuilderNoun
    ],
    "prose" => %w[Kata/NoComments Kata/ProsePlacement]
  }.freeze
  REST = "rest"
  ROW = "%-10s %6d  %s"
  NEXT = "next: %s — %d offense%s in %d file%s%s"
  MINTS = "; these mint the names `naming` then prices, so take them first"
  DENSE = "densest: %s (%d)"
  CLEAN = "clean"

  def initialize(root, io: $stdout)
    @root = root
    @io = io
  end

  def run
    found = offenses
    return clean if found.empty?
    STAGES.keys.push(REST).each { row(it, found) }
    advise(found)
    1
  end

  private

  def clean
    @io.puts(CLEAN)
    0
  end

  def row(stage, found)
    picked = within(found, stage)
    return if picked.empty?
    @io.puts(format(ROW, stage, picked.length, breakdown(picked)))
  end

  def breakdown(picked)
    picked.group_by { it.fetch("cop") }
      .sort_by { |_, list| -list.length }
      .first(3)
      .map { |cop, list| "#{cop} #{list.length}" }
      .join(", ")
  end

  def advise(found)
    picked = within(found, upcoming(found))
    @io.puts(headline(upcoming(found), picked))
    @io.puts(format(DENSE, *hottest(picked)))
  end

  def upcoming(found) = STAGES.keys.find { |stage| within(found, stage).any? } || REST

  def headline(stage, picked)
    files = picked.map { it.fetch("path") }.uniq
    format(NEXT, stage, picked.length, plural(picked), files.length, plural(files), note(stage))
  end

  def note(stage) = stage == REST ? "" : MINTS

  def hottest(picked) = picked.map { it.fetch("path") }.tally.max_by(&:last)

  def plural(list) = list.one? ? "" : "s"

  def within(found, stage) = found.select { it.fetch("stage") == stage }

  def offenses = report.fetch("files", []).flat_map { rows(it) }

  def rows(file)
    file.fetch("offenses", []).map do
      { "path" => file.fetch("path"), "cop" => it.fetch("cop_name"), "stage" => stage(it.fetch("cop_name")) }
    end
  end

  def stage(cop) = STAGES.find { |_, cops| cops.include?(cop) }&.first || REST

  def report = @_report ||= JSON.parse(inspection)

  def inspection = Dir.chdir(@root) { sweep }

  def sweep
    Tempfile.create("rubocop-kata-plan") do |sink|
      RuboCop::CLI.new.run(["--format", "json", "--out", sink.path, "."])
      File.read(sink.path)
    end
  end
end
