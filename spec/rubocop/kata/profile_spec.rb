# frozen_string_literal: true

require "tmpdir"

RSpec.describe(RuboCop::Kata::Profile) do
  def project(*files)
    Dir.mktmpdir("kata-profile") do |root|
      files.each do |path, text|
        FileUtils.mkdir_p(File.dirname(File.join(root, path)))
        File.write(File.join(root, path), text.to_s)
      end
      yield(root)
    end
  end

  let(:base) { described_class::BASE }
  let(:rails) { described_class::RAILS }
  let(:autocorrect) { described_class::AUTOCORRECT }

  it "hands a gem that runs RSpec the shipped defaults and the autocorrect allowlist, nothing more" do
    project(["shelf.gemspec", ""], [".rspec", ""]) do |root|
      expect(described_class.new(root, {}).overlay).to(eq({ "inherit_from" => [base, autocorrect] }))
    end
  end

  it "adds the Rails setting, and leaves out packaging and RSpec, for a Rails app on Minitest" do
    project(["config/application.rb", ""]) do |root|
      off = { "Enabled" => false }
      expected = { "inherit_from" => [base, autocorrect, rails], "Packaging" => off, "RSpec" => off }
      expect(described_class.new(root, {}).overlay).to(eq(expected))
    end
  end

  it "reads RSpec from the lockfile when the project keeps no .rspec" do
    lock = "GEM\n  specs:\n    rspec-core (3.13.0)\n"
    project(["shelf.gemspec", ""], ["Gemfile.lock", lock]) do |root|
      expect(described_class.new(root, {}).overlay).to(eq({ "inherit_from" => [base, autocorrect] }))
    end
  end

  it "does not take a gem that merely depends on rspec-core for one that runs it" do
    lock = "GEM\n  specs:\n    rspec-expectations (3.13.0)\n      rspec-core (~> 3.13)\n"
    project(["shelf.gemspec", ""], ["gems.locked", lock]) do |root|
      expect(described_class.new(root, {}).overlay).to(include("RSpec" => { "Enabled" => false }))
    end
  end

  # camaleon-cms: an engine keeps no config/application.rb at its root.
  it "takes a Rails engine for Rails" do
    engine = "module Shop\n  class Engine < ::Rails::Engine\n    isolate_namespace Shop\n  end\nend\n"
    project(["shop.gemspec", ""], ["lib/shop/engine.rb", engine]) do |root|
      expect(described_class.new(root, {}).overlay["inherit_from"]).to(eq([base, autocorrect, rails]))
    end
  end

  it "does not take a file merely named engine.rb for a Rails engine" do
    project(["shop.gemspec", ""], ["lib/shop/engine.rb", "class Engine\nend\n"]) do |root|
      expect(described_class.new(root, {}).overlay["inherit_from"]).to(eq([base, autocorrect]))
    end
  end

  def spoken(*files)
    project(*files) { described_class.new(it, {}).overlay.slice("Kata/RealWords", "Lint/BooleanSymbol") }
  end

  # kimera: rubocop-rspec spells `RSpecAdapter` as r_spec_adapter, since its
  # `RSpec: rspec` transform matches whole constant names only.
  it "spells a project constant that embeds RSpec or RuboCop the way the brand is spelled" do
    library = "module Shelf\n  class RSpecAdapter\n  end\n\n  class RuboCopRunner\n  end\nend\n"
    found = transforms(["shelf.gemspec", ""], ["lib/shelf.rb", "#{library}class RuboCop::Cop\nend\n"])
    expect(found).to(include("RSpecAdapter" => "rspec_adapter", "RuboCopRunner" => "rubocop_runner"))
  end

  it "leaves the transform alone when no constant embeds a brand" do
    expect(transforms(["shelf.gemspec", ""], ["lib/shelf.rb", "class RuboCop::Shelf\nend\n"])).to(be_nil)
  end

  def transforms(*files)
    project(*files) { described_class.new(it, {}).overlay.dig("RSpec/SpecFilePathFormat", "CustomTransform") }
  end

  it "takes the gem's own name for a word, and leaves dictionary words to the dictionary" do
    expect(spoken(["rubocop-kata.gemspec", ""], ["shelf.gemspec", ""]))
      .to(eq({ "Kata/RealWords" => { "Vocabulary" => %w[kata] } }))
  end

  it "takes a Rails application's module for its name" do
    application = "module FatFreeCrm\n  class Application < Rails::Application\n  end\nend\n"
    vocabulary = spoken(["config/application.rb", application]).dig("Kata/RealWords", "Vocabulary")
    expect(vocabulary).to(eq(%w[crm]))
  end

  # rubocop-kata's cops answer on_lvasgn; kimera's guards build `s(:false)`.
  it "speaks the parser's node types for a gem that depends on the parser" do
    gemspec = "Gem::Specification.new { it.add_dependency(\"rubocop-ast\", \">= 1\") }\n"
    found = spoken(["shelf.gemspec", gemspec])
    expect([found.dig("Kata/RealWords", "Vocabulary"), found["Lint/BooleanSymbol"]])
      .to(match([include("lvasgn", "dstr", "kwoptarg", "str", "arg"), { "Enabled" => false }]))
  end

  it "does not speak node types for a parser the gem only develops with" do
    gemspec = "Gem::Specification.new { it.add_development_dependency(\"rubocop\") }\n"
    expect(spoken(["shelf.gemspec", gemspec])).to(eq({}))
  end

  # kimera waits on its child processes from threads; a Rails app leaves threads to its server.
  it "leaves threads to a library, and to the server in a Rails app" do
    found = [["shelf.gemspec", ""], ["config/application.rb", ""]].map { threads(it) }
    expect(found).to(eq([false, true]))
  end

  def threads(file)
    project(file) do |root|
      YAML.load_file(described_class.new(root, {}).path, aliases: true).dig("ThreadSafety/NewThread", "Enabled")
    end
  end

  # rspec: each gem of the monorepo keeps its gemspec one level down.
  it "takes a monorepo of gems for packaged code" do
    project(["rspec-core/rspec-core.gemspec", ""], ["Gemfile", ""]) do |root|
      expect(described_class.new(root, {}).overlay).not_to(have_key("Packaging"))
    end
  end

  # Run from app/models, the plugin saw no config/application.rb and no
  # gemspec in the directory it was started from.
  it "reads the project from its root when started in a subdirectory" do
    project(["config/application.rb", ""], ["Gemfile", ""], ["app/models/user.rb", ""]) do |root|
      found = RuboCop::Kata::ProjectRoot.new(File.join(root, "app", "models")).path
      expect([found, described_class.new(found, {}).overlay["inherit_from"]])
        .to(eq([File.realpath(root), [base, autocorrect, rails]]))
    end
  end

  it "stays where it was started when no directory above marks a project" do
    project(["notes.txt", ""]) { |root| expect(RuboCop::Kata::ProjectRoot.new(root).path).to(eq(root)) }
  end

  def detects(*files)
    files.map do |file|
      project(["shelf.gemspec", ""], ["Gemfile", ""], file) { yield(described_class.new(it, {}).overlay) }
    end
  end

  # mail and reek keep no lockfile: rspec is in the gemspec or the Gemfile.
  it "reads RSpec from a gemspec, a Gemfile or the spec files" do
    gemspec = ["shelf.gemspec", "Gem::Specification.new { it.add_development_dependency(\"rspec\") }\n"]
    gemfile = ["Gemfile", "gem 'rubocop-rspec'\ngem 'rspec', '~> 3'\n"]
    described = ["spec/shelf_spec.rb", "RSpec.describe(Shelf) do\nend\n"]
    expect(detects(gemspec, gemfile, described) { it.key?("RSpec") }).to(eq([false, false, false]))
  end

  it "does not take rubocop-rspec for RSpec" do
    project(["shelf.gemspec", ""], ["Gemfile", "gem \"rubocop-rspec\"\n"]) do |root|
      expect(described_class.new(root, {}).overlay).to(include("RSpec" => { "Enabled" => false }))
    end
  end

  it "adds the Sorbet setting for sorbet-runtime in a gemspec, or a typed sigil" do
    runtime = ["bundler/shelf.gemspec", "Gem::Specification.new { it.add_dependency(\"sorbet-runtime\") }\n"]
    sigil = ["lib/shelf.rb", "# typed: strict\n# frozen_string_literal: true\n"]
    plain = ["lib/shelf.rb", "# frozen_string_literal: true\n"]
    found = detects(runtime, sigil, plain) { it["inherit_from"].include?(described_class::SORBET) }
    expect(found).to(eq([true, true, false]))
  end

  # devise: `class Engine < ::Rails::Engine` lives in lib/devise/rails.rb.
  it "takes an engine defined in any library file for Rails" do
    engine = "module Shelf\n  class Engine < ::Rails::Engine\n  end\nend\n"
    project(["shelf.gemspec", ""], ["lib/shelf/rails.rb", engine]) do |root|
      expect(described_class.new(root, {}).overlay["inherit_from"]).to(include(rails))
    end
  end

  # mail's Ragel parsers; rubygems' generated licence list.
  it "keeps generated files out, by their grammar or their header" do
    files = [
      ["shelf.gemspec", ""], ["lib/shelf/parser.rb", "module Shelf\nend\n"], ["lib/shelf/parser.rl", ""],
      ["lib/shelf/licenses.rb", "# frozen_string_literal: true\n\n# This is generated by generate_list.rb.\n"],
      ["lib/shelf/plain.rb", "# Do not panic.\n"]
    ]
    project(*files) do |root|
      excluded = described_class.new(root, {}).overlay.dig("AllCops", "Exclude").map { it.delete_prefix("#{root}/") }
      expect(excluded.sort).to(eq(%w[lib/shelf/licenses.rb lib/shelf/parser.rb]))
    end
  end

  # dependabot-core: run from bundler/, which holds its own gemspec.
  it "anchors the project at the .rubocop.yml that loads the plugin" do
    setting = "plugins:\n  - rubocop-kata\n"
    project([".rubocop.yml", setting], ["Gemfile", ""], ["bundler/shelf.gemspec", ""]) do |root|
      expect(RuboCop::Kata::ProjectRoot.new(File.join(root, "bundler")).path).to(eq(File.realpath(root)))
    end
  end

  it "keeps vendored copies out wherever they sit" do
    expect(YAML.load_file(base, aliases: true).dig("AllCops", "Exclude")).to(include("**/vendor/**/*"))
  end

  it "lets the plugin's options overrule what it detects" do
    project(["config/application.rb", ""], [".rspec", ""]) do |root|
      options = { "rails" => false, "packaging" => true, "rspec" => false }
      expected = { "inherit_from" => [base, autocorrect], "RSpec" => { "Enabled" => false } }
      expect(described_class.new(root, options).overlay).to(eq(expected))
    end
  end

  def shelved(*files)
    project(*files) do |root|
      Dir.mktmpdir("kata-shelf") { |shelf| yield(described_class.new(root, {}, shelf:), shelf) }
    end
  end

  it "writes the overlay where RuboCop can load it, and hands back the same file" do
    shelved(["config/application.rb", ""]) do |profile, shelf|
      first = profile.path
      expect([YAML.load_file(first, aliases: true)["RSpec"], profile.path, Dir.children(shelf).size])
        .to(eq([{ "Enabled" => false }, first, 1]))
    end
  end

  it "resolves the inheritance itself, since RuboCop checks an inherited file against the cops it knows" do
    shelved(["config/application.rb", ""]) do |profile, _|
      written = YAML.load_file(profile.path, aliases: true)
      names = written.dig("Kata/GoodMethodName", "AllowedNames")
      expect([written.key?("inherit_from"), names & %w[active_for_authentication default_url_options]])
        .to(eq([false, %w[active_for_authentication default_url_options]]))
    end
  end

  it "switches off each cop of a department it leaves out, since a cop enabled by name outlives its department" do
    shelved(["shelf.gemspec", ""]) do |profile, _|
      written = YAML.load_file(profile.path, aliases: true)
      cops = %w[RSpec RSpec/Output RSpec/LeakyLocalVariable Packaging/RequireHardcodingLib]
      expect(cops.map { written.dig(it, "Enabled") }).to(eq([false, false, false, false]))
    end
  end

  it "leaves the cops of the departments it keeps as shipped" do
    shelved([".rspec", ""]) do |profile, _|
      written = YAML.load_file(profile.path, aliases: true)
      expect(%w[Packaging RSpec/Output].map { written.dig(it, "Enabled") }).to(eq([false, true]))
    end
  end

  it "lets an upper layer's setting win, and adds an upper layer's list to the lower one" do
    profile = described_class.new(Dir.tmpdir, {})
    lower = { "Cop" => { "Enabled" => true, "Max" => 10, "Exclude" => %w[a] }, "plugins" => %w[x], "Old" => {} }
    upper = { "Cop" => { "Enabled" => false, "Max" => 12, "Exclude" => %w[b] }, "plugins" => "y", "Old" => nil }
    expect(profile.__send__(:layered, lower, upper))
      .to(eq({ "Cop" => { "Enabled" => false, "Max" => 12, "Exclude" => %w[a b] }, "plugins" => "y", "Old" => nil }))
  end

  it "leaves an overlay already written alone" do
    shelved(["config/application.rb", ""]) do |profile, _|
      File.utime(Time.at(0), Time.at(0), profile.path)
      expect(File.mtime(profile.path).to_i).to(eq(0))
    end
  end

  it "rewrites an overlay a crash cut short" do
    shelved(["config/application.rb", ""]) do |profile, _|
      File.write(profile.path, "inherit_from:")
      expect(YAML.load_file(profile.path, aliases: true)).to(include("Packaging" => { "Enabled" => false }))
    end
  end

  it "keeps the Rails setting to framework contracts, generated files and the server's threads" do
    setting = YAML.load_file(rails)
    names = setting.dig("Kata/GoodMethodName", "AllowedNames")
    cops = %w[GoodMethodName NoComments NoHashAsObject NoTypeCheck NoClassMethodLogic FrozenState].map { "Kata/#{it}" }
    cops << "ThreadSafety/NewThread"
    expect([setting.keys, names.include?("default_url_options"), setting.dig("Kata/NoComments", "Exclude")])
      .to(eq([cops, true, %w[bin/**/* db/**/*]]))
  end

  # register-trainee-teachers: Pundit calls `permitted_attributes_for_<action>`.
  it "lets a Rails app name the attribute lists Pundit asks a policy for" do
    patterns = YAML.load_file(rails).dig("Kata/GoodMethodName", "AllowedPatterns").map { Regexp.new(it) }
    names = %w[permitted_attributes_for_create permitted_attributes_for_update permitted_attributes]
    expect(names.map { |name| patterns.any? { name.match?(it) } }).to(eq([true, true, false]))
  end

  context "with the autocorrect allowlist" do
    let(:allowed) { entries.map(&:first) }
    let(:held) { YAML.load_file("config/autocorrect.yml") }

    def shipped
      setting = "plugins:\n  - rubocop-kata\n\nAllCops:\n  TargetRubyVersion: 3.4\n"
      files = [["shelf.gemspec", ""], [".rspec", ""], ["config/application.rb", ""], [".rubocop.yml", setting]]
      project(*files) { RuboCop::ConfigStore.new.for_dir(it) }
    end

    def entries = File.readlines("data/autocorrect.txt", chomp: true).map { it.split(" ", 3) }

    def unsafe?(setting) = setting["SafeAutoCorrect"] == false || setting["Safe"] == false

    it "lists each correction once, in order" do
      expect(allowed).to(eq(allowed.uniq.sort))
    end

    it "files every correction under layout, delimiter or equivalent, with a reason" do
      kinds = %w[layout delimiter equivalent]
      unfiled = entries.reject { |_, kind, reason| kinds.include?(kind) && reason.to_s.size > 10 }
      expect(unfiled).to(be_empty)
    end

    it "leaves the corrections that resolve a name, move an expression or split a condition to -A" do
      moved = %w[
        Style/RescueStandardError Style/GuardClause Style/SoleNestedConditional Style/StderrPuts
        Style/ParenthesesAroundCondition Lint/ImplicitStringConcatenation Naming/BinaryOperatorParameterName
        Style/ParallelAssignment Style/MultipleComparison Lint/UnifiedInteger Style/ItBlockParameter
        Style/NilComparison Style/ExplicitBlockArgument Style/RedundantCondition Style/FetchEnvVar
        Kata/NoRedundantVariable
      ]
      expect(moved & allowed).to(be_empty)
    end

    it "never holds back a correction it allows" do
      expect(held.keys & allowed).to(be_empty)
    end

    it "holds back every correction kata runs that no corpus suite has proved" do
      config = shipped
      correcting = RuboCop::Cop::Registry.global.cops.select(&:support_autocorrect?).map(&:cop_name)
      loose = correcting.select { config.cop_enabled?(it) && !allowed.include?(it) && !unsafe?(config.for_cop(it)) }
      expect(loose).to(be_empty)
    end

    it "lets rubocop -a run what the allowlist names" do
      config = shipped
      proved = %w[Layout/TrailingWhitespace Style/StringLiterals]
      expect(proved.map { unsafe?(config.for_cop(it)) }).to(eq([false, false]))
    end
  end
end
