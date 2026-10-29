# frozen_string_literal: true

require "yaml"

class RuboCop::Kata::Entries
  INERT = "%s:%d: `%s` is disabled by the configuration this project inherits; the entry does nothing."
  MOVED = "%s:%d: `%s` was renamed to `%s`; rename the entry."
  OFF = "%s: `DisabledByDefault: true` leaves %d of kata's %d cops off: RuboCop runs only the cops the project's " \
    "files enable by name; enable each by name (`Kata/GoodMethodName:` with `Enabled: true`), or drop the key."
  KEY = %r{\A([A-Z]\w*/\w+):}
  DEFAULTED = /\A\s*DisabledByDefault:\s*true\b/
  SHIPPED = File.expand_path("../../../config/default.yml", __dir__)

  def initialize(root, config, renames)
    @root = root
    @config = config
    @renames = renames
  end

  def dead = defaulted + inert

  def inert
    keys.filter_map { |path, line, key, own| format(INERT, path, line, key) unless @renames.to(key) || live?(key, own) }
  end

  def moved
    @_moved ||= keys.filter_map { |path, line, key| @renames.to(key)&.then { format(MOVED, path, line, key, it) } }
  end

  def defaulted
    off = kata.reject { @config.cop_enabled?(it) }
    @config.for_all_cops["DisabledByDefault"] == true && off.any? ? [format(OFF, defaulting, off.size, kata.size)] : []
  end

  private

  def keys
    @_keys ||=
      files.flat_map do |file|
        own = settings(file)
        lines(file).filter_map { |text, line| text[KEY, 1]&.then { [shown(file), line, it, own] } }
      end
  end

  def live?(key, own) = @config.cop_enabled?(key) || own.dig(key, "Enabled") == false

  def kata
    shipped = YAML.load_file(SHIPPED, aliases: true)
    shipped.filter_map { |name, setting| name if name.start_with?("Kata/") && setting["Enabled"] == true }
  end

  def defaulting
    found = files.lazy.filter_map { |file| lines(file).find { DEFAULTED.match?(it.first) }&.then { [file, it.last] } }
    found.first&.then { |file, line| "#{shown(file)}:#{line}" } || ".rubocop.yml"
  end

  def lines(file) = File.readlines(file, encoding: Encoding::UTF_8).each.with_index(1).to_a

  def shown(file) = file.delete_prefix("#{@root}/")

  def settings(file) = YAML.safe_load_file(file, aliases: true) || {}

  def files(file = File.join(@root, ".rubocop.yml"), seen = [])
    return seen if seen.include?(file) || !File.file?(file)
    Array(settings(file)["inherit_from"]).reduce([*seen, file]) do |found, path|
      files(File.expand_path(path, File.dirname(file)), found)
    end
  end
end
