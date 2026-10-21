# frozen_string_literal: true

require "yaml"
require_relative "renames"

class RuboCop::Kata::Checkup
  INERT = "%s:%d: `%s` is disabled by the configuration this project inherits; the entry does nothing."
  DEAD = "%s:%d: the directive names `%s`, which is not enabled here; the comment does nothing."
  RENAMED = "%s:%d: the directive names `%s`, which RuboCop renamed to `%s`; the comment does nothing."
  UNREAD = "%s: not checked, %s."
  BROKEN = "%s: does not parse as Ruby %s, the target version; its directives were read only as far as the parser got."
  UNLOADED = "%s: the project's configuration does not load (%s); %s."
  BUNDLED = "run doctor through the project's bundle, `bundle exec rubocop-kata doctor`"
  TALLY = "%d dead entr%s"
  SKIPPED = ", %d file%s not fully checked"
  KEY = %r{\A([A-Z]\w*/\w+):}

  def initialize(root, io: $stdout)
    @root = root
    @io = io
  end

  def run
    examine
  rescue ::LoadError, RuboCop::Error => error
    cause = error.message.lines.first.to_s.strip
    @io.puts(format(UNLOADED, @root, cause, cause.include?("renamed to") ? "rename it in .rubocop.yml" : BUNDLED))
    2
  end

  private

  def examine
    found = inert + dead
    clean = clean?(found)
    [*waivers.lines, *notes, *found, clean ? "clean" : tally(found), *waivers.tally].each { @io.puts(it) }
    clean ? 0 : 1
  end

  def clean?(found) = found.empty? && notes.empty? && waivers.bare.zero?

  def tally(found)
    text = format(TALLY, found.size, found.one? ? "y" : "ies")
    notes.empty? ? text : text + format(SKIPPED, notes.size, plural(notes))
  end

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
      source.comments.flat_map do |comment|
        directive = RuboCop::DirectiveComment.new(comment)
        directive.start_with_marker? && !directive.all_cops? ? stale(path, directive) : []
      end
    end
  end

  def stale(path, directive)
    moved, gone = directive.cop_names.reject { active?(it, path) }.partition { renames.to(it) }
    renamed = moved.map { format(RENAMED, path, directive.line_number, it, renames.to(it)) }
    gone.empty? ? renamed : [*renamed, format(DEAD, path, directive.line_number, gone.join("`, `"))]
  end

  def renames = @_renames ||= RuboCop::Kata::Renames.new

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

  def waivers = @_waivers ||= RuboCop::Kata::Waivers.new(parsed)

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
