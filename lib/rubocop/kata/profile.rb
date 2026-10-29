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
  BRANDS = { "RuboCop" => "Rubocop", "RSpec" => "Rspec" }.freeze
  SPELLED = { "RuboCop" => "rubocop", "RSpec" => "rspec" }.freeze
  WORD = /\A[a-z][a-z0-9]+\z/
  LIBRARY = { "Kata/ClassInModule" => { "Exclude" => ["lib/*.rb"] } }.freeze
  def initialize(root, options, shelf: Dir.tmpdir, retirement: RuboCop::Kata::Retirement.new)
    @root = root
    @options = options
    @shelf = shelf
    @retirement = retirement
  end

  def path
    layer = overlay
    text = YAML.dump(@retirement.kept(silenced(standalone(layer), layer)))
    target = File.join(@shelf, "rubocop-kata-#{Digest::SHA256.hexdigest(text)[0, 16]}.yml")
    publish(target, text) unless File.file?(target) && File.read(target, encoding: Encoding::UTF_8) == text
    target
  end

  def overlay
    survey = RuboCop::Kata::Survey.new(@root)
    layer = { "inherit_from" => [BASE, AUTOCORRECT, *rails(survey), *sorbet(survey)] }
    { "Packaging" => :packaged?, "RSpec" => :rspec? }.each do |department, found|
      layer[department] = { "Enabled" => false } unless chosen(department.downcase) { survey.public_send(found) }
    end
    layer.merge(skipped(survey), spoken(survey), owned(survey), survey.autoloads? ? LIBRARY : {})
  end

  private

  def skipped(survey)
    generated = survey.generated
    generated.empty? ? {} : { "AllCops" => { "Exclude" => generated } }
  end

  def spoken(survey)
    words = (survey.names + coined(survey)).uniq.reject { plain?(it) }
    layer = words.empty? ? {} : { "Kata/RealWords" => { "Vocabulary" => words } }
    layer = layer.merge(transforms(survey))
    return layer unless survey.parser?
    spoken = layer.fetch("Kata/RealWords", {}).merge("NodeCallbacks" => true)
    layer.merge("Kata/RealWords" => spoken, "Lint/BooleanSymbol" => { "Enabled" => false })
  end

  def owned(survey)
    roots = survey.roots
    layer = roots.empty? ? {} : { "Kata" => { "Roots" => roots } }
    checked = { "Dependencies" => survey.dependencies.sort, "Protocols" => (survey.framework? ? %w[rails] : []) }
    checked = checked.reject { |_, value| value.empty? }
    checked.empty? ? layer : layer.merge("Kata/NoTypeCheck" => checked)
  end

  def coined(survey)
    (survey.dependencies.flat_map { parts(it) } + named(survey) + nodes(survey)).reject { clipping?(it) }
  end

  def parts(gem) = gem.downcase.split(/[-_.]/).grep(WORD)

  def named(survey) = survey.constants.flat_map { spelled(it).split("_") }.grep(WORD)

  def spelled(name) = snake(BRANDS.reduce(name) { |text, (brand, word)| text.gsub(brand, word) })

  def transforms(survey)
    found =
      (survey.constants - SPELLED.keys).filter_map do |name|
        path = spelled(name)
        [name, path] unless path == snake(name)
      end
    found.empty? ? {} : { "RSpec/SpecFilePathFormat" => { "CustomTransform" => SPELLED.merge(found.to_h) } }
  end

  def snake(name) = name.gsub(/([^A-Z])([A-Z]+)/, '\1_\2').gsub(/([A-Z])([A-Z][^A-Z\d]+)/, '\1_\2').downcase

  def nodes(survey) = survey.parser? ? Parser::Meta::NODE_TYPES.map(&:to_s).grep(WORD) : []

  def plain?(word) = RuboCop::Kata::Dictionary::ENTRIES.include?(word) && !clipping?(word)

  def clipping?(word) = RuboCop::Kata::Dictionary::CLIPPINGS.key?(word)

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

  def rails(survey)
    application = chosen("rails") { survey.rails? }
    application || chosen("rails") { survey.framework? } ? [FRAMEWORK, *(RAILS if application)] : []
  end

  def sorbet(survey) = chosen("sorbet") { survey.sorbet? } ? [SORBET] : []

  def chosen(key)
    choice = @options[key]
    choice.nil? ? yield : choice == true
  end
end
