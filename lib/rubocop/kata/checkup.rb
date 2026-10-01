# frozen_string_literal: true

require "yaml"

class RuboCop::Kata::Checkup
  INERT = "%s:%d: `%s` is disabled by the configuration this project inherits; the entry does nothing."
  DEAD = "%s:%d: the directive names `%s`, which is not enabled here; the comment does nothing."
  TALLY = "%d dead entr%s"
  KEY = %r{\A([A-Z]\w*/\w+):}

  def initialize(root, io: $stdout)
    @root = root
    @io = io
  end

  def run
    found = inert + dead
    clean = found.empty?
    found.each { @io.puts(it) }
    @io.puts(clean ? "clean" : tally(found))
    clean ? 0 : 1
  end

  private

  def tally(found) = format(TALLY, found.length, found.one? ? "y" : "ies")

  def inert
    entries.filter_map { |key, line| format(INERT, file, line, key) unless live?(key) }
  end

  def entries
    lines.each_with_index.filter_map { |text, index| [text[KEY, 1], index + 1] if text.match?(KEY) }
  end

  def lines = File.file?(file) ? File.readlines(file) : []

  def file = File.join(@root, ".rubocop.yml")

  def live?(key) = config.cop_enabled?(key) || off?(key)

  def off?(key) = project.dig(key, "Enabled") == false

  def project = @_project ||= YAML.safe_load_file(file, aliases: true) || {}

  def dead = targets.flat_map { directives(it) }

  def targets = RuboCop::TargetFinder.new(store).find([@root], :only_recognized_file_types)

  def directives(path)
    RuboCop::ProcessedSource.from_file(path, config.target_ruby_version).comments
      .map { RuboCop::DirectiveComment.new(it) }
      .filter_map { finding(path, it) }
  rescue StandardError
    []
  end

  def finding(path, directive)
    return unless directive.start_with_marker? && !directive.all_cops?
    stale = directive.cop_names.reject { active?(it, path) }
    return if stale.empty?
    format(DEAD, path, directive.line_number, stale.join("`, `"))
  end

  def active?(name, path)
    configuration = store.for_file(path)
    cop = RuboCop::Cop::Registry.global.find_by_cop_name(name)
    configuration.cop_enabled?(name) && cop&.new(configuration)&.relevant_file?(path)
  end

  def config = @_config ||= store.for_dir(@root)

  def store = @_store ||= RuboCop::ConfigStore.new
end
