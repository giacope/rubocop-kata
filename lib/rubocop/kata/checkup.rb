# frozen_string_literal: true

require "yaml"

class RuboCop::Kata::Checkup
  INERT = "%s:%d: `%s` is disabled by the configuration this project inherits; the entry does nothing."
  DEAD = "%s:%d: the directive names `%s`, which is not enabled here; the comment does nothing."
  UNREAD = "%s: not checked, %s."
  BROKEN = "%s: does not parse; its directives were read only as far as the parser got."
  WAIVER = "%s:%d: disables `%s` — %s"
  BARE = "no reason given"
  TALLY = "%d dead entr%s"
  SKIPPED = ", %d file%s not fully checked"
  WAIVERS = "%d inline disable%s, %d without a reason"
  KEY = %r{\A([A-Z]\w*/\w+):}

  def initialize(root, io: $stdout)
    @root = root
    @io = io
  end

  def run
    found = inert + dead
    [*waivers, *notes, *found].each { @io.puts(it) }
    @io.puts(summary(found))
    clean?(found) ? 0 : 1
  end

  private

  def clean?(found) = found.empty? && notes.empty?

  def summary(found) = [clean?(found) ? "clean" : tally(found), *count].join("\n")

  def count = waived.empty? ? [] : [format(WAIVERS, waived.size, plural(waived), waived.count { it.last.empty? })]

  def tally(found)
    text = format(TALLY, found.size, found.one? ? "y" : "ies")
    notes.empty? ? text : text + format(SKIPPED, notes.size, plural(notes))
  end

  def plural(list) = list.one? ? "" : "s"

  def inert = files.flat_map { |file| entries(file) }

  def entries(file)
    own = settings(file)
    File.readlines(file, encoding: Encoding::UTF_8).each_with_index.filter_map do |text, index|
      key = text[KEY, 1]
      format(INERT, relative(file), index + 1, key) if key && !live?(key, own)
    end
  end

  def settings(file) = YAML.safe_load_file(file, aliases: true) || {}

  def files(file = File.join(@root, ".rubocop.yml"), seen = [])
    return seen if seen.include?(file) || !File.file?(file)
    seen << file
    parents(file).each { files(it, seen) }
    seen
  end

  def parents(file) = Array(settings(file)["inherit_from"]).map { File.expand_path(it, File.dirname(file)) }

  def live?(key, own) = config.cop_enabled?(key) || own.dig(key, "Enabled") == false

  def relative(path) = path.delete_prefix("#{@root}/")

  def dead = parsed.flat_map { |path, source| source.comments.filter_map { finding(path, it) } }

  def notes = @_notes ||= sources.filter_map { |path, source| note(path, source) }

  def note(path, source)
    return format(UNREAD, path, source) if source.is_a?(String)
    format(BROKEN, path) unless source.valid_syntax?
  end

  def parsed = sources.reject { |_, source| source.is_a?(String) }

  def sources = @_sources ||= targets.map { [it, parse(it)] }

  def parse(path)
    source = RuboCop::ProcessedSource.from_file(path, config.target_ruby_version)
    source.comments
    source
  rescue StandardError => error
    "#{error.class}: #{error.message.lines.first.to_s.strip}"
  end

  def targets = RuboCop::TargetFinder.new(store).find([@root], :only_recognized_file_types)

  def finding(path, comment)
    directive = RuboCop::DirectiveComment.new(comment)
    return unless directive.start_with_marker? && !directive.all_cops?
    stale = directive.cop_names.reject { active?(it, path) }
    return if stale.empty?
    format(DEAD, path, directive.line_number, stale.join("`, `"))
  end

  def waivers = waived.map { |path, line, cops, reason| format(WAIVER, path, line, cops, explained(reason)) }

  def explained(reason) = reason.empty? ? BARE : reason

  def waived = @_waived ||= parsed.flat_map { |path, source| waivers_in(path, source) }

  def waivers_in(path, source)
    source.comments.map { RuboCop::Kata::Waiver.new(it) }.select(&:disabling?)
      .map { [path, it.line, it.cops.join("`, `"), it.reason.to_s] }
  end

  def active?(name, path)
    configuration = store.for_file(path)
    cop = RuboCop::Cop::Registry.global.find_by_cop_name(name)
    configuration.cop_enabled?(name) && cop&.new(configuration)&.relevant_file?(path)
  end

  def config = @_config ||= store.for_dir(@root)

  def store = @_store ||= RuboCop::ConfigStore.new
end
