# frozen_string_literal: true

require "json"
require "rbconfig"
require "tempfile"

class RuboCop::Kata::Plan
  STAGES = {
    "structure" => %w[
      Kata/ConstructorDiscipline Kata/NoClassMethodLogic Kata/NoHashAsObject
      Kata/NoBooleanFlag Kata/IoDiscipline Kata/ClockDiscipline Kata/EnvDiscipline Kata/FailFast
      Kata/ScopedResource
      Kata/ClassInModule Kata/NoRedundantVariable
      Kata/NoSetter Kata/FrozenState Kata/NoOutputArgument Kata/CommandQuery
      Kata/NoTypeCheck Kata/NoSingleton Kata/NoNilArgument Kata/NoNilReturn Kata/NoHardWiring
      Kata/NoGetter Kata/FieldCount Kata/PublicSurface Kata/NoPublicConstant Kata/NoReflection
      Kata/NoMonkeyPatch Kata/NoMock
    ],
    "naming" => %w[
      Kata/RealWords Kata/GoodMethodName Kata/GoodVariableName Kata/GoodClassName
      Kata/GoodModuleName Kata/BuilderNoun
    ],
    "prose" => %w[Kata/NoComments Kata/ProsePlacement Kata/JustifiedDirective],
    "layout" => %w[Kata/PairedBrackets Kata/NoEmptyLinesInMethods Kata/NoEmptyLinesInBlocks]
  }.freeze
  DEPARTMENTS = { "Layout/" => "layout" }.freeze
  REST = "rest"
  ROW = "%-10s %6d  %s"
  NEXT = "next: %s — %d offense%s in %d file%s%s"
  MINTS = "; these mint the names `naming` then prices, so take them first"
  NOTES = { "structure" => MINTS }.freeze
  DENSE = "densest: %s (%d)"
  CLEAN = "clean"
  LAUNCH = 'require "rubocop"; exit(RuboCop::CLI.new.run(ARGV))'

  def initialize(root, io: $stdout)
    @root = root
    @io = io
  end

  def run
    found = offenses
    @io.puts(found.empty? ? CLEAN : table(found) + advice(found))
    found.empty? ? 0 : 1
  end

  private

  def table(found)
    STAGES.keys.push(REST).filter_map do |stage|
      picked = within(found, stage)
      format(ROW, stage, picked.length, breakdown(picked)) unless picked.empty?
    end
  end

  def breakdown(picked)
    picked.map { it.fetch("cop") }.tally
      .sort_by { |_, count| -count }
      .first(3)
      .map { |cop, count| "#{cop} #{count}" }
      .join(", ")
  end

  def advice(found)
    stage = upcoming(found)
    picked = within(found, stage)
    files = picked.map { it.fetch("path") }
    [
      format(NEXT, stage, picked.length, plural(picked), files.uniq.length, plural(files.uniq), NOTES.fetch(stage, "")),
      format(DENSE, *files.tally.max_by(&:last))
    ]
  end

  def upcoming(found) = STAGES.keys.find { |stage| within(found, stage).any? } || REST

  def plural(list) = list.one? ? "" : "s"

  def within(found, stage) = found.select { it.fetch("stage") == stage }

  def offenses
    report.fetch("files", []).flat_map do |file|
      file.fetch("offenses", []).map do
        cop = it.fetch("cop_name")
        { "path" => file.fetch("path"), "cop" => cop, "stage" => stage(cop) }
      end
    end
  end

  def stage(cop)
    STAGES.find { |_, cops| cops.include?(cop) }&.first ||
      DEPARTMENTS.find { |prefix, _| cop.start_with?(prefix) }&.last || REST
  end

  def report
    @_report ||=
      Tempfile.create("rubocop-kata-plan") do |sink|
        arguments = ["--format", "json", "--out", sink.path, "--plugin", "rubocop-kata", "."]
        system(RbConfig.ruby, "-e", LAUNCH, "--", *arguments, chdir: @root)
        JSON.parse(File.read(sink.path, encoding: Encoding::UTF_8))
      end
  end
end
