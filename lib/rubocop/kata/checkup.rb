# frozen_string_literal: true

require "yaml"

class RuboCop::Kata::Checkup
  INERT = "%s:%d: `%s` is disabled by the configuration this project inherits; the entry does nothing."
  DEAD = "%s:%d: the directive names `%s`, which is not enabled here; the comment does nothing."
  UNREAD = "%s: not checked, %s."
  BROKEN = "%s: does not parse as Ruby %s, the target version; its directives were read only as far as the parser got."
  UNLOADED = "%s: the project's configuration does not load (%s); run doctor through the project's bundle, " \
    "`bundle exec rubocop-kata doctor`."
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
    examine
  rescue ::LoadError, RuboCop::Error => error
    @io.puts(format(UNLOADED, @root, error.message.lines.first.to_s.strip))
    2
  end

  private

  def examine
    found = inert + dead
    clean = found.empty? && notes.empty?
    [*waivers, *notes, *found, clean ? "clean" : tally(found), *count].each { @io.puts(it) }
    clean ? 0 : 1
  end

  def tally(found)
    text = format(TALLY, found.size, found.one? ? "y" : "ies")
    notes.empty? ? text : text + format(SKIPPED, notes.size, plural(notes))
  end

  def count = waived.empty? ? [] : [format(WAIVERS, waived.size, plural(waived), waived.count { it.last.empty? })]

  def plural(list) = list.one? ? "" : "s"

  def inert
    files.flat_map do |file|
      own = settings(file)
      File.readlines(file, encoding: Encoding::UTF_8).each_with_index.filter_map do |text, index|
        key = text[KEY, 1]
        format(INERT, file.delete_prefix("#{@root}/"), index + 1, key) if key && !live?(key, own)
      end
    end
  end

  def settings(file) = YAML.safe_load_file(file, aliases: true) || {}

  def files(file = File.join(@root, ".rubocop.yml"), seen = [])
    return seen if seen.include?(file) || !File.file?(file)
    Array(settings(file)["inherit_from"]).reduce([*seen, file]) do |found, path|
      files(File.expand_path(path, File.dirname(file)), found)
    end
  end

  def live?(key, own) = config.cop_enabled?(key) || own.dig(key, "Enabled") == false

  def dead
    parsed.flat_map do |path, source|
      source.comments.filter_map do |comment|
        directive = RuboCop::DirectiveComment.new(comment)
        next unless directive.start_with_marker? && !directive.all_cops?
        stale = directive.cop_names.reject { active?(it, path) }
        format(DEAD, path, directive.line_number, stale.join("`, `")) unless stale.empty?
      end
    end
  end

  def active?(name, path)
    configuration = store.for_file(path)
    cop = RuboCop::Cop::Registry.global.find_by_cop_name(name)
    configuration.cop_enabled?(name) && cop&.new(configuration)&.relevant_file?(path)
  end

  def notes
    @_notes ||=
      sources.filter_map do |path, source|
        next format(UNREAD, path, source) if source.is_a?(String)
        format(BROKEN, path, config.target_ruby_version) unless source.valid_syntax?
      end
  end

  def waivers
    waived.map { |path, line, cops, reason| format(WAIVER, path, line, cops, reason.empty? ? BARE : reason) }
  end

  def waived
    @_waived ||=
      parsed.flat_map do |path, source|
        source.comments.map { RuboCop::Kata::Waiver.new(it) }.select(&:disabling?)
          .map { [path, it.line, it.cops.join("`, `"), it.reason] }
      end
  end

  def parsed = sources.reject { |_, source| source.is_a?(String) }

  def sources
    @_sources ||=
      RuboCop::TargetFinder.new(store).find([@root], :only_recognized_file_types).map do |path|
        [path, RuboCop::ProcessedSource.from_file(path, config.target_ruby_version)]
      rescue StandardError => error
        [path, "#{error.class}: #{error.message.lines.first.to_s.strip}"]
      end
  end

  def config = @_config ||= store.for_dir(@root)

  def store = @_store ||= RuboCop::ConfigStore.new
end
