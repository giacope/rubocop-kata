# frozen_string_literal: true

require "digest"
require "tmpdir"
require "yaml"

class RuboCop::Kata::Profile
  SHELF = File.expand_path("../../../config", __dir__)
  BASE = File.join(SHELF, "default.yml")
  RAILS = File.join(SHELF, "rails.yml")
  FRAMEWORK = File.join(SHELF, "framework.yml")
  SORBET = File.join(SHELF, "sorbet.yml")
  AUTOCORRECT = File.join(SHELF, "autocorrect.yml")
  LIBRARY = { "Kata/ClassInModule" => { "Exclude" => ["lib/*.rb"] } }.freeze
  def initialize(root, options, shelf: Dir.tmpdir)
    @root = root
    @options = options
    @shelf = shelf
  end

  def path
    layer = overlay
    text = YAML.dump(silenced(standalone(layer), layer))
    target = File.join(@shelf, "rubocop-kata-#{Digest::SHA256.hexdigest(text)[0, 16]}.yml")
    publish(target, text) unless File.file?(target) && File.read(target, encoding: Encoding::UTF_8) == text
    target
  end

  def overlay
    folder = RuboCop::Kata::Folder.new(@root)
    survey = RuboCop::Kata::Survey.new(@root, folder)
    manifest = RuboCop::Kata::Manifest.new(folder)
    layer = { "inherit_from" => [BASE, AUTOCORRECT, *rails(survey, manifest), *sorbet(survey)] }
    layer.merge(unused(survey, manifest), learned(folder, manifest), survey.autoloads? ? LIBRARY : {})
  end

  private

  def unused(survey, manifest)
    used = { "Packaging" => -> { manifest.packaged? }, "RSpec" => -> { survey.rspec? } }
    off = used.reject { |department, found| chosen(department.downcase, &found) }.keys
    off.to_h { [it, { "Enabled" => false }] }
  end

  def learned(folder, manifest)
    codebase = RuboCop::Kata::Codebase.new(@root, folder)
    skipped(codebase).merge(RuboCop::Kata::Lexicon.new(codebase, manifest).to_h, owned(codebase, manifest))
  end

  def skipped(codebase)
    generated = codebase.generated
    generated.empty? ? {} : { "AllCops" => { "Exclude" => generated } }
  end

  def owned(codebase, manifest)
    roots = codebase.roots
    layer = roots.empty? ? {} : { "Kata" => { "Roots" => roots } }
    checked = { "Dependencies" => manifest.dependencies.sort, "Protocols" => (manifest.framework? ? %w[rails] : []) }
    checked = checked.reject { |_, value| value.empty? }
    checked.empty? ? layer : layer.merge("Kata/NoTypeCheck" => checked)
  end

  def standalone(layer)
    files = layer.fetch("inherit_from").map { YAML.load_file(it, aliases: true) }
    [*files, layer.except("inherit_from")].reduce { |lower, upper| layered(lower, upper) }
  end

  def layered(lower, upper)
    return lower | upper if lower.is_a?(Array) && upper.is_a?(Array)
    return upper unless lower.is_a?(Hash) && upper.is_a?(Hash)
    lower.merge(upper) { |_, low, high| layered(low, high) }
  end

  def silenced(merged, layer)
    departments = layer.select { |_, value| value == { "Enabled" => false } }.keys
    merged.to_h { |key, value| [key, departments.include?(key[%r{\A[^/]+}]) ? value.merge("Enabled" => false) : value] }
  end

  def publish(target, text)
    draft = "#{target}.#{Process.pid}"
    File.write(draft, text)
    File.rename(draft, target)
  end

  def rails(survey, manifest)
    application = chosen("rails") { survey.rails? }
    application || chosen("rails") { manifest.framework? } ? [FRAMEWORK, *(RAILS if application)] : []
  end

  def sorbet(survey) = chosen("sorbet") { survey.sorbet? } ? [SORBET] : []

  def chosen(key)
    choice = @options[key]
    choice.nil? ? yield : choice == true
  end
end
