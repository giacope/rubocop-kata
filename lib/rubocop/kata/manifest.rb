# frozen_string_literal: true

class RuboCop::Kata::Manifest
  MANIFESTS = %w[Gemfile gems.rb Gemfile.lock gems.locked *.gemspec */Gemfile */*.gemspec].freeze
  GEMSPECS = %w[*.gemspec */*.gemspec].freeze
  PARSER = /\.add_(?:runtime_)?dependency[\s(]*["'](?:parser|rubocop|rubocop-ast|unparser)["']/
  FRAMEWORK = /\.add_(?:runtime_)?dependency[\s(]*["'](?:activerecord|activemodel|activesupport|railties|rails)["']/
  REQUIRED = [
    /^ {4}([A-Za-z0-9][\w.-]*) \(/, /^\s*gem[\s(]+["']([\w.-]+)["']/,
    /\.add_(?:runtime_|development_)?dependency[\s(]*["']([\w.-]+)["']/
  ].freeze

  def initialize(folder)
    @folder = folder
  end

  def packaged? = @folder.paths(*GEMSPECS).any?

  def parser? = @folder.mentions?(GEMSPECS, PARSER)

  def framework? = @folder.mentions?(GEMSPECS, FRAMEWORK)

  def dependencies
    @folder.texts(*MANIFESTS).flat_map { |text| REQUIRED.flat_map { text.scan(it) } }.flatten.uniq - gems
  end

  private

  def gems = @folder.paths(*GEMSPECS).map { File.basename(it, ".gemspec") }
end
