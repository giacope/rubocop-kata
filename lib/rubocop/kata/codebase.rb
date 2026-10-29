# frozen_string_literal: true

class RuboCop::Kata::Codebase
  GEMSPECS = %w[*.gemspec */*.gemspec].freeze
  LIBRARY = %w[lib/**/*.rb */lib/**/*.rb app/**/*.rb */app/**/*.rb].freeze
  APPLICATION = File.join("config", "application.rb")
  NAMESPACE = /^\s*module\s+([A-Z]\w*)/
  DEFINITION = /^\s*(?:class|module)\s+([A-Z][\w:]*)/
  REQUIRE = %r{^\s*require(?:_relative)?[\s(]+["']([\w/.-]+)["']}

  def initialize(root, folder = RuboCop::Kata::Folder.new(root))
    @root = root
    @folder = folder
  end

  def names = [*gems, *application.map { snake(it) }].flat_map { it.split(/[-_.]/) }.uniq

  def roots = [*Dir.glob(GEMSPECS, base: @root).map { root(it) }, *application].uniq

  def constants = sources.flat_map { read(it).scan(DEFINITION) }.flatten.flat_map { it.split("::") }.uniq

  def generated = sources.select { RuboCop::Kata::Origin.new(it).generated? }

  private

  def sources = @folder.sources(*LIBRARY)

  def gems = Dir.glob(GEMSPECS, base: @root).map { File.basename(it, ".gemspec") }

  def application = @folder.texts(APPLICATION).join.scan(NAMESPACE).flatten.first(1)

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

  def read(path) = File.read(path, encoding: Encoding::UTF_8).scrub
end
