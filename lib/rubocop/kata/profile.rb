# frozen_string_literal: true

require "digest"
require "pathname"
require "tmpdir"
require "yaml"

class RuboCop::Kata::Profile
  SHELF = File.expand_path("../../../config", __dir__)
  BASE = File.join(SHELF, "default.yml")
  RAILS = File.join(SHELF, "rails.yml")
  AUTOCORRECT = File.join(SHELF, "autocorrect.yml")
  LOCKS = %w[Gemfile.lock gems.locked].freeze
  RSPEC = /^ {4}rspec-core \(/
  MARKERS = %w[Gemfile gems.rb *.gemspec config/application.rb].freeze
  GEMSPECS = %w[*.gemspec */*.gemspec].freeze
  ENGINE = /<\s*(::)?Rails::Engine\b|^\s*isolate_namespace\b/

  def initialize(start, options, shelf: Dir.tmpdir)
    @start = start
    @options = options
    @shelf = shelf
  end

  def root = @_root ||= Pathname(@start).expand_path.ascend.map(&:to_s).find { marked?(it) } || @start

  def path
    layer = overlay
    text = YAML.dump(silenced(standalone(layer), layer))
    target = File.join(@shelf, "rubocop-kata-#{Digest::SHA256.hexdigest(text)[0, 16]}.yml")
    publish(target, text) unless File.file?(target) && File.read(target) == text
    target
  end

  def overlay
    layer = { "inherit_from" => [BASE, AUTOCORRECT, *(RAILS if rails?)] }
    layer["Packaging"] = { "Enabled" => false } unless packaged?
    layer["RSpec"] = { "Enabled" => false } unless specified?
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

  def marked?(dir) = MARKERS.any? { Dir.glob(it, base: dir).any? }

  def silenced(merged, layer)
    departments = layer.select { |_, value| value == { "Enabled" => false } }.keys
    merged.to_h { |key, value| [key, departments.include?(key[%r{\A[^/]+}]) ? value.merge("Enabled" => false) : value] }
  end

  def publish(target, text)
    draft = "#{target}.#{Process.pid}"
    File.write(draft, text)
    File.rename(draft, target)
  end

  def rails? = chosen("rails") { File.file?(File.join(root, "config", "application.rb")) || engine? }

  def engine? = Dir.glob("lib/**/engine.rb", base: root).any? { ENGINE.match?(File.read(File.join(root, it))) }

  def packaged? = chosen("packaging") { Dir.glob(GEMSPECS, base: root).any? }

  def specified? = chosen("rspec") { File.file?(File.join(root, ".rspec")) || RSPEC.match?(lockfile) }

  def lockfile
    found = LOCKS.map { File.join(root, it) }.find { File.file?(it) }
    found ? File.read(found) : ""
  end

  def chosen(key)
    choice = @options[key]
    choice.nil? ? yield : choice == true
  end
end
