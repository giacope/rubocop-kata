# frozen_string_literal: true

class RuboCop::Kata::Survey
  MANIFESTS = %w[Gemfile gems.rb Gemfile.lock gems.locked *.gemspec */Gemfile */*.gemspec].freeze
  LIBRARY = %w[lib/**/*.rb */lib/**/*.rb app/**/*.rb */app/**/*.rb].freeze
  ENGINES = %w[lib/**/*.rb */lib/**/*.rb].freeze
  RSPEC = %w[rspec rspec-core rspec-rails].freeze
  SORBET = %w[sorbet sorbet-runtime sorbet-static].freeze
  ENGINE = /<\s*(::)?Rails::Engine\b|^\s*isolate_namespace\b/
  APPLICATION = File.join("config", "application.rb")
  AUTOLOADED = /^\s*config\.(?:autoload_lib|(?:autoload|eager_load)_paths\b.*\blib["']?\s*(?:[)\]]|$))/
  DESCRIBE = /^\s*RSpec\.describe\b/

  def initialize(root, folder = RuboCop::Kata::Folder.new(root))
    @root = root
    @folder = folder
  end

  def rails? = File.file?(File.join(@root, APPLICATION)) || @folder.sources(*ENGINES).any? { ENGINE.match?(read(it)) }

  def autoloads? = AUTOLOADED.match?(@folder.texts(APPLICATION).join)

  def rspec?
    return true if File.file?(File.join(@root, ".rspec")) || uses?(RSPEC)
    @folder.sources("spec/**/*_spec.rb").first(50).any? { DESCRIBE.match?(read(it)) }
  end

  def sorbet? = uses?(SORBET) || @folder.sources(*LIBRARY).first(20).any? { RuboCop::Kata::Origin.new(it).typed? }

  private

  def uses?(gems)
    names = gems.join("|")
    @folder.mentions?(MANIFESTS, /["'](#{names})["']|^ {4}(#{names}) \(/)
  end

  def read(path) = File.read(path, encoding: Encoding::UTF_8).scrub
end
