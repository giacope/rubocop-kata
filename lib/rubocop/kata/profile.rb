# frozen_string_literal: true

require "digest"
require "tmpdir"
require "yaml"

class RuboCop::Kata::Profile
  SHELF = File.expand_path("../../../config", __dir__)
  BASE = File.join(SHELF, "default.yml")
  RAILS = File.join(SHELF, "rails.yml")
  LOCKS = %w[Gemfile.lock gems.locked].freeze
  RSPEC = /^ {4}rspec-core \(/

  def initialize(root, options, shelf: Dir.tmpdir)
    @root = root
    @options = options
    @shelf = shelf
  end

  def path
    layer = overlay
    return BASE if layer == { "inherit_from" => [BASE] }
    text = YAML.dump(silenced(standalone(layer), layer))
    target = File.join(@shelf, "rubocop-kata-#{Digest::SHA256.hexdigest(text)[0, 16]}.yml")
    publish(target, text) unless File.file?(target) && File.read(target) == text
    target
  end

  def overlay
    layer = { "inherit_from" => [BASE, *(RAILS if rails?)] }
    layer["Packaging"] = { "Enabled" => false } unless packaged?
    layer["RSpec"] = { "Enabled" => false } unless specified?
    layer
  end

  private

  def standalone(layer)
    files = layer.fetch("inherit_from").map { YAML.load_file(it, aliases: true) }
    [*files, layer.except("inherit_from")].reduce do |lower, upper|
      lower.merge(upper) { |_, low, high| low.merge(high) { |_, old, new| old | new } }
    end
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

  def rails? = chosen("rails") { File.file?(File.join(@root, "config", "application.rb")) }

  def packaged? = chosen("packaging") { Dir.glob("*.gemspec", base: @root).any? }

  def specified? = chosen("rspec") { File.file?(File.join(@root, ".rspec")) || RSPEC.match?(lockfile) }

  def lockfile
    found = LOCKS.map { File.join(@root, it) }.find { File.file?(it) }
    found ? File.read(found) : ""
  end

  def chosen(key)
    choice = @options[key]
    choice.nil? ? yield : choice == true
  end
end
