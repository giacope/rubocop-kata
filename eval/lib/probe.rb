# frozen_string_literal: true

require "json"
require "rubocop"
require "yaml"

config = RuboCop::ConfigStore.new.for_dir(ARGV.fetch(0))
core = YAML.safe_load_file(RuboCop::ConfigLoader::DEFAULT_FILE, aliases: true, permitted_classes: [Regexp, Symbol])
names = RuboCop::Cop::Registry.global.cops.map(&:cop_name)
shipped = names.select { [true, "pending"].include?(core.dig(it, "Enabled")) }
silenced = shipped.reject { config.cop_enabled?(it) }
listed = ->(cop, key) { Array(config.for_cop(cop)[key]) }
allowed = listed.call("Kata/GoodClassName", "AllowedNames") + listed.call("Kata/GoodModuleName", "AllowedNames")

$stdout.puts(
  JSON.dump(
    "kata_cops" => names.count { it.start_with?("Kata/") },
    "kata_cops_enabled" => names.count { it.start_with?("Kata/") && config.cop_enabled?(it) },
    "class_allowed_names" => listed.call("Kata/GoodClassName", "AllowedNames").size,
    "module_allowed_names" => listed.call("Kata/GoodModuleName", "AllowedNames").size,
    "allowed_names_total" => allowed.size,
    "allowed_names_distinct" => allowed.uniq.size,
    "class_suffixes" => listed.call("Kata/GoodClassName", "Suffixes").size,
    "banned_words" => listed.call("Kata/RealWords", "BannedWords").size,
    "core_cops_silenced" => silenced.size,
    "layout_cops_silenced" => silenced.count { it.start_with?("Layout/") },
    "layout_silenced" => silenced.select { it.start_with?("Layout/") },
    "no_comments_safe_autocorrect" => config.for_cop("Kata/NoComments").fetch("SafeAutoCorrect", true),
    "no_comments_allow_documentation" => config.for_cop("Kata/NoComments")["AllowDocumentation"],
    "inline_disable_banned" => config.cop_enabled?("Style/DisableCopsWithinSourceCodeDirective"),
    "memoized_ivar_autocorrect" => config.for_cop("Naming/MemoizedInstanceVariableName").fetch("AutoCorrect", true),
    "method_length_count_as_one" => listed.call("Metrics/MethodLength", "CountAsOne"),
    "abc_size_max" => config.for_cop("Metrics/AbcSize")["Max"]
  )
)
