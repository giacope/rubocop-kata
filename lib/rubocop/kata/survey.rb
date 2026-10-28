# frozen_string_literal: true

class RuboCop::Kata::Survey
  MANIFESTS = %w[Gemfile gems.rb Gemfile.lock gems.locked *.gemspec */Gemfile */*.gemspec].freeze
  GEMSPECS = %w[*.gemspec */*.gemspec].freeze
  LIBRARY = %w[lib/**/*.rb */lib/**/*.rb app/**/*.rb */app/**/*.rb].freeze
  ENGINES = %w[lib/**/*.rb */lib/**/*.rb].freeze
  RSPEC = %w[rspec rspec-core rspec-rails].freeze
  SORBET = %w[sorbet sorbet-runtime sorbet-static].freeze
  ENGINE = /<\s*(::)?Rails::Engine\b|^\s*isolate_namespace\b/
  APPLICATION = File.join("config", "application.rb")
  AUTOLOADED = /^\s*config\.(?:autoload_lib|(?:autoload|eager_load)_paths\b.*\blib["']?\s*(?:[)\]]|$))/
  NAMESPACE = /^\s*module\s+([A-Z]\w*)/
  DEFINITION = /^\s*(?:class|module)\s+([A-Z][\w:]*)/
  PARSER = /\.add_(?:runtime_)?dependency[\s(]*["'](?:parser|rubocop|rubocop-ast|unparser)["']/
  FRAMEWORK = /\.add_(?:runtime_)?dependency[\s(]*["'](?:activerecord|activemodel|activesupport|railties|rails)["']/
  SIGIL = /^#\s*typed:\s*\w/
  DESCRIBE = /^\s*RSpec\.describe\b/
  REQUIRED = [
    /^ {4}([A-Za-z0-9][\w.-]*) \(/, /^\s*gem[\s(]+["']([\w.-]+)["']/,
    /\.add_(?:runtime_|development_)?dependency[\s(]*["']([\w.-]+)["']/
  ].freeze
  REQUIRE = %r{^\s*require(?:_relative)?[\s(]+["']([\w/.-]+)["']}
  BOUND = 3000
  HEADER = 40

  def initialize(root)
    @root = root
  end

  def rails? = File.file?(File.join(@root, APPLICATION)) || sources(*ENGINES).any? { ENGINE.match?(read(it)) }

  def packaged? = Dir.glob(GEMSPECS, base: @root).any?

  def autoloads? = AUTOLOADED.match?(setup)

  def parser? = depends?(PARSER)

  def framework? = depends?(FRAMEWORK)

  def names = [*gems, *application.map { snake(it) }].flat_map { it.split(/[-_.]/) }.uniq

  def roots = [*Dir.glob(GEMSPECS, base: @root).map { root(it) }, *application].uniq

  def dependencies
    texts = Dir.glob(MANIFESTS, base: @root).map { read(File.join(@root, it)) }
    texts.flat_map { |text| REQUIRED.flat_map { text.scan(it) } }.flatten.uniq - gems
  end

  def constants = sources(*LIBRARY).flat_map { read(it).scan(DEFINITION) }.flatten.flat_map { it.split("::") }.uniq

  def rspec?
    return true if File.file?(File.join(@root, ".rspec")) || uses?(RSPEC)
    sources("spec/**/*_spec.rb").first(50).any? { DESCRIBE.match?(read(it)) }
  end

  def sorbet? = uses?(SORBET) || sources(*LIBRARY).first(20).any? { SIGIL.match?(header(it).join) }

  def generated = sources(*LIBRARY).select { RuboCop::Kata::Origin.new(it, header(it)).generated? }

  private

  def gems = Dir.glob(GEMSPECS, base: @root).map { File.basename(it, ".gemspec") }

  def application = setup.scan(NAMESPACE).flatten.first(1)

  def setup = Dir.glob(APPLICATION, base: @root).map { read(File.join(@root, it)) }.join

  def root(gemspec)
    gem = File.basename(gemspec, ".gemspec")
    lib = File.join(@root, File.dirname(gemspec), "lib")
    names = required(lib, gem) || shipped(lib)
    names ? names.join("::") : camelized(gem)
  end

  def required(lib, gem)
    spelled = [gem.tr("-", "/"), *entered(lib, gem)].map { spelled(it) }
    names, = spelled.find(&:last) || spelled.max_by { it.first.size }
    names unless names.empty?
  end

  def entered(lib, gem)
    entry = File.join(lib, "#{gem}.rb")
    return [] unless File.file?(entry)
    read(entry).scan(REQUIRE).flatten.map { it.delete_suffix(".rb") }.select { File.file?(File.join(lib, "#{it}.rb")) }
  end

  def shipped(lib)
    paths = Dir.glob("**/*.rb", base: lib).sort_by { [it.count("/"), it] }
    paths.lazy.map { spelled(it.delete_suffix(".rb")) }.find(&:last)&.first
  end

  def spelled(path)
    segments = path.split("/")
    names = segments.map { spellings[it.delete("_").downcase] }.take_while(&:itself)
    [names, names.size == segments.size]
  end

  def spellings = @_spellings ||= constants.to_h { [it.delete("_").downcase, it] }

  def camelized(gem) = gem.split("-").map { |part| part.split(/[_.]/).map(&:capitalize).join }.join("::")

  def snake(name) = name.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase

  def depends?(pattern) = mentions?(GEMSPECS, pattern)

  def uses?(gems)
    names = gems.join("|")
    mentions?(MANIFESTS, /["'](#{names})["']|^ {4}(#{names}) \(/)
  end

  def mentions?(manifests, pattern)
    Dir.glob(manifests, base: @root).any? { pattern.match?(read(File.join(@root, it))) }
  end

  def sources(*patterns) = Dir.glob(patterns, base: @root).first(BOUND).map { File.join(@root, it) }

  def header(path)
    File.foreach(path, encoding: Encoding::UTF_8).lazy.map(&:scrub).first(HEADER)
      .take_while { it.strip.empty? || it.lstrip.start_with?("#") }
  end

  def read(path) = File.read(path, encoding: Encoding::UTF_8).scrub
end
