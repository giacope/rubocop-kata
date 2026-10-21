# frozen_string_literal: true

require "digest"
require "tmpdir"
require "yaml"

class RuboCop::Kata::Profile
  SHELF = File.expand_path("../../../config", __dir__)
  BASE = File.join(SHELF, "default.yml")
  RAILS = File.join(SHELF, "rails.yml")
  SORBET = File.join(SHELF, "sorbet.yml")
  AUTOCORRECT = File.join(SHELF, "autocorrect.yml")
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
    survey = RuboCop::Kata::Survey.new(@root)
    layer = { "inherit_from" => [BASE, AUTOCORRECT, *(RAILS if chosen("rails") { survey.rails? }), *sorbet(survey)] }
    { "Packaging" => :packaged?, "RSpec" => :rspec? }.each do |department, found|
      layer[department] = { "Enabled" => false } unless chosen(department.downcase) { survey.public_send(found) }
    end
    skipped = survey.generated
    layer["AllCops"] = { "Exclude" => skipped } unless skipped.empty?
    layer
  end

  private

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

  def sorbet(survey) = chosen("sorbet") { survey.sorbet? } ? [SORBET] : []

  def chosen(key)
    choice = @options[key]
    choice.nil? ? yield : choice == true
  end
end
