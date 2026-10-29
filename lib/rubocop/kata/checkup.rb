# frozen_string_literal: true

require "yaml"
require_relative "renames"
require_relative "entries"

class RuboCop::Kata::Checkup
  DEAD = "%s:%d: the directive names `%s`, which is not enabled here; the comment does nothing."
  RENAMED = "%s:%d: the directive names `%s`, which RuboCop renamed to `%s`; the comment does nothing."
  UNREAD = "%s: not checked, %s."
  BROKEN = "%s: does not parse as Ruby %s, the target version; its directives were read only as far as the parser got."
  UNLOADED = "%s: the project's configuration does not load (%s); %s."
  BUNDLED = "run doctor through the project's bundle, `bundle exec rubocop-kata doctor`"
  TALLY = "%d dead entr%s"
  MOVES = ", %d entr%s to rename"
  SKIPPED = ", %d file%s not fully checked"

  def initialize(root, io: $stdout, files: RuboCop::ProcessedSource)
    @root = root
    @io = io
    @files = files
  end

  def run = outcome.fetch(0).each { @io.puts(it) }

  def status = outcome.fetch(1)

  private

  def outcome = @_outcome ||= examined

  def examined
    examine
  rescue ::LoadError, RuboCop::Error => error
    cause = error.message.lines.first.to_s.strip
    [[format(UNLOADED, @root, cause, cause.include?("renamed to") ? "rename it in .rubocop.yml" : BUNDLED)], 2]
  end

  def examine
    entries = RuboCop::Kata::Entries.new(@root, config)
    renames = RuboCop::Kata::Renames.new
    found = entries.dead + dead(renames)
    moved = entries.moved
    waivers = RuboCop::Kata::Waivers.new(parsed)
    clean = clean?(found, moved, waivers)
    verdict = clean ? "clean" : tally(found, moved)
    [[*waivers.lines, *notes, *found, *moved, verdict, *waivers.tally], clean ? 0 : 1]
  end

  def clean?(found, moved, waivers) = found.empty? && moved.empty? && notes.empty? && waivers.bare.zero?

  def tally(found, moved)
    text = counted(TALLY, found) + (moved.empty? ? "" : counted(MOVES, moved))
    notes.empty? ? text : text + format(SKIPPED, notes.size, plural(notes))
  end

  def counted(template, list) = format(template, list.size, list.one? ? "y" : "ies")

  def plural(list) = list.one? ? "" : "s"

  def dead(renames)
    parsed.flat_map do |path, source|
      source.comments.flat_map do |comment|
        directive = RuboCop::DirectiveComment.new(comment)
        directive.start_with_marker? && !directive.all_cops? ? stale(path, directive, renames) : []
      end
    end
  end

  def stale(path, directive, renames)
    moved, gone = directive.cop_names.reject { active?(it, path) }.partition { renames.renamed?(it) }
    renamed = moved.map { format(RENAMED, path, directive.line_number, it, renames.to(it)) }
    gone.empty? ? renamed : [*renamed, format(DEAD, path, directive.line_number, gone.join("`, `"))]
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

  def parsed = sources.reject { |_, source| source.is_a?(String) }

  def sources
    @_sources ||=
      RuboCop::TargetFinder.new(store).find([@root], :only_recognized_file_types).map do |path|
        [path, @files.from_file(path, config.target_ruby_version)]
      rescue StandardError => error
        [path, "#{error.class}: #{error.message.lines.first.to_s.strip}"]
      end
  end

  def config = @_config ||= store.for_dir(@root)

  def store = @_store ||= RuboCop::ConfigStore.new
end
