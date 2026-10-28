# frozen_string_literal: true

require "open3"
require "tmpdir"

RSpec.describe(RuboCop::Kata::Plugin) do
  let(:plugin) { described_class.new }
  let(:shipped) { YAML.load_file("config/default.yml", aliases: true) }

  def effective
    Dir.mktmpdir("kata-config") do |root|
      File.write(File.join(root, ".rubocop.yml"), "plugins:\n  - rubocop-kata\n")
      yield(RuboCop::ConfigStore.new.for_dir(root))
    end
  end

  it "runs under RuboCop" do
    expect(plugin.supported?(LintRoller::Context.new(engine: :rubocop))).to(be(true))
  end

  it "declines any other engine" do
    expect(plugin.supported?(LintRoller::Context.new(engine: :standard))).to(be(false))
  end

  it "hands RuboCop the shipped defaults, with the corrections -a may not run held back" do
    written = YAML.load_file(plugin.rules(LintRoller::Context.new(engine: :rubocop)).value, aliases: true)
    expect([written.dig("Kata/NoComments", "Enabled"), written.dig("Bundler/OrderedGems", "SafeAutoCorrect")])
      .to(eq([true, false]))
  end

  it "hands its options to the profile, so a project can ask for the Rails setting" do
    path = described_class.new("rails" => true).rules(LintRoller::Context.new(engine: :rubocop)).value
    names = YAML.load_file(path, aliases: true).dig("Kata/GoodMethodName", "AllowedNames")
    expect(names).to(include("default_url_options"))
  end

  it "leaves every cop it tunes switched on, unless it switches one off itself" do
    tuned = shipped.select { |key, value| key.include?("/") && value.is_a?(Hash) && !value.key?("Enabled") }.keys
    effective { |config| expect(tuned.select { config.for_cop(it)["Enabled"] == false }).to(be_empty) }
  end

  # refinerycms: each engine of the monorepo holds its own app/ (core/app/controllers/application_controller.rb).
  it "reads an engine's <gem>/app like app/ wherever a default names app/", :aggregate_failures do
    lists = shipped.values.grep(Hash).flat_map { it.values_at("OwnedPaths", "Exclude").compact }
    paths = [*lists, RuboCop::Cop::Kata::Reopening::OWNED, RuboCop::Cop::Kata::Contract::OWNED]
    missing = paths.flat_map { |list| list.grep(%r{\Aapp/}).reject { list.include?("*/#{it}") } }
    expect(missing).to(be_empty)
    expect(paths.count { it.include?("*/app/**/*.rb") }).to(eq(16))
  end

  it "keeps the parameter limit it advertises" do
    effective do |config|
      expect(config.for_cop("Metrics/ParameterLists").slice("Enabled", "Max")).to(eq("Enabled" => true, "Max" => 4))
    end
  end

  it "accepts a module, a class, or a compact namespace, as the README says" do
    effective do |config|
      expect(%w[Elegant/NoClassInModule Kata/ClassInModule].map { config.for_cop(it)["Enabled"] }).to(eq([false, true]))
    end
  end

  it "switches on no cop a later RuboCop adds, and leaves none it ships pending" do
    effective do |config|
      pending = config.to_h.keys.select { it.include?("/") && config.for_cop(it)["Enabled"] == "pending" }
      expect([config.for_all_cops["NewCops"], pending]).to(eq(["disable", []]))
    end
  end

  it "reports rescue variables to rename without renaming half their readers" do
    effective do |config|
      expect(config.for_cop("Naming/RescuedExceptionsVariableName").slice("PreferredName", "AutoCorrect"))
        .to(eq("PreferredName" => "error", "AutoCorrect" => false))
    end
  end

  it "keeps the corrections it knows to break code out of rubocop -a" do
    effective do |config|
      cops = %w[
        Style/EmptyClassDefinition Style/Proc Style/SingleLineMethods Style/Lambda Style/DefWithParentheses
        Style/OperatorMethodCall Performance/BindCall Style/EmptyMethod Style/CaseEquality Lint/UselessNumericOperation
      ]
      expect(cops.reject { config.for_cop(it)["SafeAutoCorrect"] == false }).to(be_empty)
    end
  end

  it "reads `+` as string concatenation only when a string literal starts it" do
    effective do |config|
      expect(config.for_cop("Style/StringConcatenation")["Mode"]).to(eq("conservative"))
    end
  end

  it "leaves type annotations alone, as Kata/NoComments promises" do
    effective do |config|
      expect(config.for_cop("Layout/LeadingCommentSpace").slice("AllowRBSInlineAnnotation", "AllowSteepAnnotation"))
        .to(eq("AllowRBSInlineAnnotation" => true, "AllowSteepAnnotation" => true))
    end
  end

  it "switches off the layout and packaging cops that loop or crash" do
    effective do |config|
      expect(%w[Layout/EmptyLineBetweenDefs Packaging/RequireHardcodingLib].map { config.cop_enabled?(it) })
        .to(eq([false, false]))
    end
  end

  def layout(source)
    effective do |config|
      cops = RuboCop::Cop::Registry.global.cops.select { %i[Layout Elegant].include?(it.department) }
      running = cops.select { config.cop_enabled?(it.cop_name) }.map { it.new(config) }
      investigated(running, RuboCop::ProcessedSource.new(source, 3.4, File.join(Dir.pwd, "lib/pick.rb")), config)
    end
  end

  def investigated(cops, parsed, config)
    parsed.config = config
    RuboCop::Cop::Commissioner.new(cops, [], raise_error: true).investigate(parsed).offenses.map(&:cop_name)
  end

  # searchkick: `-a` took a clean `if (\n a ||\n b\n)` to `if a ||\n   b`, a step of three, which nothing then fixed.
  it "lets a multi-line condition continue two columns in, the step every layout cop it runs accepts" do
    condition = "def pick(a, b)\n  if a.present? ||\n    b.present?\n    a\n  end\nend\n"
    expect(layout("# frozen_string_literal: true\n\n#{condition}")).to(be_empty)
  end

  # refinerycms: an engine's own Zeitwerk root, core/app/controllers/application_controller.rb.
  it "leaves a top-level class in a Zeitwerk root to Rails, an engine's included, and nowhere else" do
    paths = %w[
      app/models/account.rb app/models/concerns/archivable.rb app/jobs/sweep_job.rb
      core/app/controllers/application_controller.rb core/app/models/concerns/archivable.rb
      app/models/billing/invoice.rb lib/invoice.rb core/lib/invoice.rb
    ]
    config = RuboCop::Config.new(shipped.slice("Kata/ClassInModule"), "/shop/.rubocop.yml")
    cop = RuboCop::Cop::Kata::ClassInModule.new(config)
    expect(paths.map { cop.relevant_file?(File.join("/shop", it)) })
      .to(eq([false, false, false, false, false, true, true, true]))
  end

  # doorkeeper, pagy, rake and twelve more corpus projects set an AllCops Exclude of their own. RuboCop
  # anchors a plugin's paths where it first loads it, so the run gets a process of its own.
  it "keeps skipping vendored copies and the schema when the project excludes paths of its own" do
    own = "plugins:\n  - rubocop-kata\nAllCops:\n  Exclude:\n    - \"tmp/**/*\"\n"
    files = { ".rubocop.yml" => own, "Gemfile" => "", "lib/shelf.rb" => "", "lib/shelf/vendor/tsort/sorter.rb" => "" }
    listed = targets(files.merge("tmp/cache.rb" => "", "db/schema.rb" => ""))
    expect(listed).to(eq(%w[Gemfile lib/shelf.rb]))
  end

  # config/strict.yml: the strict Elegant Objects profile a project inherits on top of the plugin.
  it "switches on exactly the rules it ships off, and the cops they replace off, under the strict profile" do
    plain = settings("")
    strict = settings("inherit_gem:\n  rubocop-kata: config/strict.yml\n")
    changed = strict.to_h { |name, values| [name, values.reject { |key, value| plain.dig(name, key) == value }] }
    expect(changed.reject { |_, values| values.empty? }).to(eq(strict_profile))
  end

  # A project whose plugins sit in a parent file: RuboCop checks an inherited file's cops before that parent's plugins.
  it "runs the strict profile where the project's plugins sit in another inherited file" do
    expect(linted(parented, "--only", "Kata/FailFast")).to(include("1 file inspected, 1 offense detected"))
  end

  def parented
    {
      "base.yml" => "plugins:\n  - rubocop-kata\nAllCops:\n  TargetRubyVersion: 3.4\n",
      ".rubocop.yml" => "inherit_from: base.yml\ninherit_gem:\n  rubocop-kata: config/strict.yml\n",
      "count.rb" => "def count = Integer(@text) rescue 0\n"
    }
  end

  def linted(files, *options)
    Dir.mktmpdir("kata-config") do |root|
      files.each { |path, text| File.write(File.join(root, path), text) }
      Open3.capture2e(RbConfig.ruby, Gem.bin_path("rubocop", "rubocop"), *options, chdir: root).first
    end
  end

  def settings(extra)
    Dir.mktmpdir("kata-config") do |root|
      File.write(File.join(root, ".rubocop.yml"), "plugins:\n  - rubocop-kata\n#{extra}")
      config = RuboCop::ConfigStore.new.for_dir(root)
      RuboCop::Cop::Registry.global.names.to_h { [it, config.for_cop(it)] }
    end
  end

  def strict_profile
    added = %w[
      FailFast ScopedResource NoNilArgument NoNilReturn NoHardWiring NoGetter FieldCount PublicSurface
      NoPublicConstant NoReflection
    ]
    readings = {
      "IoDiscipline" => "CheckEffects", "ClockDiscipline" => "CheckRandomness", "EnvDiscipline" => "CheckSettings",
      "NoSingleton" => "CheckGlobals", "CommandQuery" => "CheckEveryQuery", "ConstructorDiscipline" => "CheckPaths",
      "GoodClassName" => "CheckContracts", "BuilderNoun" => "CheckEveryBuilder"
    }
    replaced = %w[Lint/SuppressedException Style/RescueModifier Elegant/NoNilReturn Style/Send]
    [
      *added.map { ["Kata/#{it}", { "Enabled" => true }] },
      *readings.map { |cop, key| ["Kata/#{cop}", { key => true }] },
      *replaced.map { [it, { "Enabled" => false }] }
    ].to_h
  end

  def targets(files)
    Dir.mktmpdir("kata-config") do |root|
      files.each do |path, text|
        FileUtils.mkdir_p(File.dirname(File.join(root, path)))
        File.write(File.join(root, path), text)
      end
      listed, = Open3.capture2(RbConfig.ruby, Gem.bin_path("rubocop", "rubocop"), "-L", "--cache", "false", chdir: root)
      listed.lines.map { it.chomp.delete_prefix("#{File.realpath(root)}/") }.sort
    end
  end

  def upstream
    gems = %w[rubocop-performance rubocop-rspec rubocop-thread_safety rubocop-packaging]
    shipped = gems.map { File.join(Gem.loaded_specs[it].gem_dir, "config/default.yml") }
    files = [RuboCop::ConfigLoader::DEFAULT_FILE, *shipped]
    files.map { YAML.safe_load_file(it, permitted_classes: [Regexp, Symbol], aliases: true) }.reduce(:merge)
  end

  def silenced
    elegant = File.join(Gem.loaded_specs["rubocop-elegant"].gem_dir, "config/default.yml")
    settings = YAML.load_file(elegant, aliases: true)
    settings.select { |name, setting| name.include?("/") && setting.is_a?(Hash) && setting["Enabled"] == false }.keys
  end

  # Why each cop RuboCop ships on and rubocop-elegant switches off stays off in kata.
  def kept_off
    {
      "Layout/EmptyLineAfterGuardClause" => "Kata/NoEmptyLinesInMethods forbids the blank line it asks for",
      "Naming/MethodName" => "Kata/GoodMethodName holds every segment of a name to its lowercase Pattern",
      "Naming/VariableName" => "Kata/GoodVariableName holds every segment of a name to its lowercase Pattern",
      "Style/ClassAndModuleChildren" => "a module, a class and a compact namespace all name one (Kata/ClassInModule)",
      "Style/Documentation" => "Kata/NoComments decides which comment documents a definition",
      "Style/IfUnlessModifier" => "a layout preference: a modifier and a block `if` both read, and kata picks neither",
      "Style/MultilineBlockChain" => "a pipeline of blocks reads in order; Metrics/BlockLength bounds each block",
      "Style/RedundantException" => "Style/ImplicitRuntimeError, on through rubocop-elegant, wants the class it drops"
    }
  end

  it "turns back on each cop RuboCop ships on and rubocop-elegant switches off, or says why it stays off" do
    leaked = silenced.select { upstream.dig(it, "Enabled") == true }
    effective do |config|
      on = leaked.select { config.for_cop(it)["Enabled"] == true }
      expect([leaked - on - kept_off.keys, kept_off.keys - (leaked - on)]).to(eq([[], []]))
    end
  end

  it "reports class variables and a method defined inside another, which rubocop-elegant lets pass" do
    effective do |config|
      expect(%w[Style/ClassVars Lint/NestedMethodDefinition].map { config.for_cop(it)["Enabled"] }).to(eq([true, true]))
    end
  end
end
