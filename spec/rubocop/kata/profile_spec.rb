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

  def shelf = { "Kata" => { "Roots" => %w[Shelf] } }

  it "hands a gem that runs RSpec the shipped defaults, the -a allowlist and its name, nothing more" do
    project(["shelf.gemspec", ""], [".rspec", ""]) do |root|
      expect(described_class.new(root, {}).overlay).to(eq({ "inherit_from" => [base, autocorrect], **shelf }))
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
    lock = "PATH\n  specs:\n    shelf (0.1)\n\nGEM\n  specs:\n    rspec-core (3.13.0)\n"
    checked = { "Kata/NoTypeCheck" => { "Dependencies" => %w[rspec-core] } }
    found = project(["shelf.gemspec", ""], ["Gemfile.lock", lock]) { described_class.new(it, {}).overlay }
    expect(found).to(eq({ "inherit_from" => [base, autocorrect], **shelf, **checked }))
  end

  it "does not take a gem that merely depends on rspec-core for one that runs it" do
    lock = "GEM\n  specs:\n    rspec-expectations (3.13.0)\n      rspec-core (~> 3.13)\n"
    project(["shelf.gemspec", ""], ["gems.locked", lock]) do |root|
      expect(described_class.new(root, {}).overlay).to(include("RSpec" => { "Enabled" => false }))
    end
  end

  # camaleon-cms: an engine keeps no config/application.rb at its root.
  def excluded(setting)
    text = "module Shop\n  class Application < Rails::Application\n    #{setting}\n  end\nend\n"
    project(["config/application.rb", text]) { described_class.new(it, {}).overlay["Kata/ClassInModule"] }
  end

  # content-tagger and support: `config.autoload_lib`, which `rails new` writes since 7.1, makes lib/ a Zeitwerk root.
  it "takes lib/ for a Zeitwerk root where the application autoloads it" do
    loading = [
      "config.autoload_lib(ignore: %w[assets tasks])", "config.eager_load_paths << Rails.root.join(\"lib\")",
      "config.autoload_paths += Dir[Rails.root.join('lib')]", "config.autoload_paths << \"\#{config.root}/lib\""
    ]
    expect(loading.map { excluded(it) }).to(eq([{ "Exclude" => ["lib/*.rb"] }] * 4))
  end

  it "leaves lib/ to the namespace rule where the application does not autoload it" do
    other = [
      "# config.autoload_lib(ignore: %w[assets tasks])", "config.eager_load_paths << Rails.root.join(\"lib\", \"x\")",
      "config.autoload_paths << Rails.root.join(\"lib/extras\")", "config.add_autoload_paths_to_load_path = true"
    ]
    expect(other.map { excluded(it) }).to(eq([nil] * 4))
  end

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
    spoken = found.fetch("Kata/RealWords")
    expect([spoken["Vocabulary"], spoken["NodeCallbacks"], found["Lint/BooleanSymbol"]])
      .to(match([include("lvasgn", "dstr", "kwoptarg"), true, { "Enabled" => false }]))
  end

  # rubocop and opal: `*args` and `str` are clippings there as anywhere else.
  it "keeps the clippings and the parts of a node type out of the parser's words" do
    gemspec = "Gem::Specification.new { it.add_dependency(\"parser\") }\n"
    words = spoken(["shelf.gemspec", gemspec]).dig("Kata/RealWords", "Vocabulary")
    expect(words).not_to(include("str", "args", "op", "asgn"))
  end

  # alonetone's `@pagy`, kamal's `sshkit`: a dependency's name is a technology's.
  it "takes the names of the project's dependencies for words, but not a clipping" do
    lock = "GEM\n  specs:\n    pagy (9.0)\n    govuk_design_system_formbuilder (5.0)\n"
    gemspec = "Gem::Specification.new { it.add_development_dependency(\"keyring\") }\n"
    files = [["Gemfile", "gem \"sshkit\"\ngem(\"cmd-runner\")\n"], ["Gemfile.lock", lock], ["shelf.gemspec", gemspec]]
    expect(spoken(*files).dig("Kata/RealWords", "Vocabulary")).to(eq(%w[sshkit pagy govuk formbuilder keyring]))
  end

  # zeitwerk: `Zeitwerk::Cref` makes `cref` one of its words.
  it "takes the project's own constant names for words" do
    library = "module Zeitwerk\n  class Cref\n  end\n\n  class RSpecArgs\n  end\nend\n"
    expect(spoken(["lib/zeitwerk/cref.rb", library]).dig("Kata/RealWords", "Vocabulary")).to(eq(%w[cref]))
  end

  it "names the project's root constants after its gems and its Rails application" do
    application = "module FatFreeCrm\n  class Application < Rails::Application\n  end\nend\n"
    files = [["rubocop-kata.gemspec", ""], ["ruby_event_store/ruby_event_store.gemspec", ""]]
    project(*files, ["config/application.rb", application]) do |root|
      expect(described_class.new(root, {}).overlay.dig("Kata", "Roots"))
        .to(eq(%w[Rubocop::Kata RubyEventStore FatFreeCrm]))
    end
  end

  # refinerycms-core defines `Refinery::Core`, test-prof `TestProf`, http `HTTP`: a root is the namespace the gem
  # defines, through its require path or what its entry file requires, spelled as the code spells it.
  it "takes a gem's root from the namespace it defines, not from its camelized name" do
    files = [
      ["refinerycms.gemspec", ""], ["lib/refinerycms.rb", "require 'refinery/all'\n"], ["lib/refinery/all.rb", ""],
      ["core/refinerycms-core.gemspec", ""], ["core/lib/refinerycms-core.rb", "require 'refinery/core'\n"],
      ["core/lib/refinery/core.rb", "module Refinery\n  module Core\n  end\nend\n"],
      ["prof/test-prof.gemspec", ""], ["prof/lib/test-prof.rb", "require \"test_prof\"\nmodule RuboCop\nend\n"],
      ["prof/lib/test_prof.rb", "module TestProf\nend\n"],
      ["http/http.gemspec", ""], ["http/lib/http.rb", "module HTTP\nend\n"],
      ["shelf/shelfcms-core.gemspec", ""], ["shelf/lib/shelf/core.rb", "module Shelf\n  module Core\n  end\nend\n"]
    ]
    project(*files) do |root|
      expect(described_class.new(root, {}).overlay.dig("Kata", "Roots").sort)
        .to(eq(%w[HTTP Refinery Refinery::Core Shelf::Core TestProf]))
    end
  end

  # shoulda-matchers, paper_trail: a library built on ActiveRecord probes its API.
  it "reads Rails' protocols for a library that depends on ActiveRecord, ActiveModel or ActiveSupport" do
    built = ["shelf.gemspec", "Gem::Specification.new { it.add_dependency(\"activerecord\") }\n"]
    found = [built, ["shelf.gemspec", ""]].map { |file| project(file) { described_class.new(it, {}).overlay } }
    found = found.map { it["Kata/NoTypeCheck"] }
    expect(found).to(eq([{ "Dependencies" => %w[activerecord], "Protocols" => %w[rails] }, nil]))
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

  # devise: `class Engine < ::Rails::Engine` lives in lib/devise/rails.rb; refinerycms's in core/lib/refinery/….
  it "takes an engine defined in any library file for Rails, an engine gem's in the monorepo too" do
    engine = "module Shelf\n  class Engine < ::Rails::Engine\n  end\nend\n"
    places = [["lib/shelf/rails.rb", engine], ["core/lib/shelf/core/engine.rb", engine]]
    found = places.map { |file| project(["shelf.gemspec", ""], file) { described_class.new(it, {}).overlay } }
    expect(found.map { it["inherit_from"] }).to(all(include(rails)))
  end

  # mail's Ragel parsers; rubygems' generated licence list.
  it "keeps generated files out, by their grammar or their header" do
    files = [
      ["shelf.gemspec", ""], ["lib/shelf/parser.rb", "module Shelf\nend\n"], ["lib/shelf/parser.rl", ""],
      ["lib/shelf/licenses.rb", "# frozen_string_literal: true\n\n# This is generated by generate_list.rb.\n"],
      ["lib/shelf/plain.rb", "# Do not panic.\n"],
      ["app/controllers/users_controller.rb", "# This controller has been generated to enable resource routes.\n"],
      ["lib/shelf/stub.rb", "# @generated\nmodule Shelf\nend\n"],
      ["lib/shelf/table.rb", "# Auto-generated from the schema.\n"], ["lib/shelf/lexer.rb", "#\n# DO NOT EDIT\n"],
      ["lib/shelf/tokens.rb", "# Do not modify this file.\n"]
    ]
    excluded = project(*files) { |root| skipped(root).map { it.delete_prefix(root) } }
    expect(excluded.sort).to(eq((files.map { "/#{it.first}" }.grep(/\.rb\z/) - %w[/lib/shelf/plain.rb]).sort))
  end

  def skipped(root) = described_class.new(root, {}).overlay.dig("AllCops", "Exclude")

  # One list for hashira and rubocop-kata (G7): what a file's leading comments say when a tool wrote it.
  # stripe-ruby opens 1,249 files with "File generated from our OpenAPI spec", nokogiri its jars file with
  # "this is a generated file". hashira's spec/hashira/project_spec.rb asserts the same headers.
  def generated_headers
    [
      "# File generated from our OpenAPI spec\n", "# This file was generated by Racc\n",
      "# @generated\nmodule A; end\n", "# Code generated by openapi-generator. DO NOT EDIT.\n",
      "# Auto-generated from the schema.\n", "# autogenerated by bin/regen\n",
      "# this is a generated file, to avoid over-writing it just delete this comment\n",
      "# A generated file: see script/gen.\n", "#\n# DO NOT MODIFY\n", "# This controller has been generated.\n",
      "# frozen_string_literal: true\n\n# This is generated by generate_list.rb.\n",
      "# frozen_string_literal: true\n#{"#\n" * 12}# do not edit: regenerate with rake gen\n"
    ]
  end

  def written_headers
    [
      "x = 'generated by hand'\n", "class H\n  # links generated by the tab component\nend\n",
      "# frozen_string_literal: true\n\nmodule Shelf\n  # These are generated by nodes.\n  Fragment = 1\nend\n",
      "# Regenerated nightly, edit freely.\n", "# Generates the report.\nclass Report; end\n",
      "require \"x\"\n# DO NOT EDIT below\n", "# The @generatedAt stamp is kept.\n"
    ]
  end

  it "takes a file for generated when its leading comments say so, never for prose after the first code line" do
    files = [*generated_headers, *written_headers].each_with_index.map { |text, at| ["lib/shelf/f#{at}.rb", text] }
    excluded = project(["shelf.gemspec", ""], *files) { |root| skipped(root).map { it.delete_prefix("#{root}/") } }
    expect(excluded.sort).to(eq(files.first(generated_headers.size).map(&:first).sort))
  end

  # opal's lib/opal/fragment.rb: "These are generated by nodes" documents the class.
  it "reads the marker in the comment block a file opens with, not in the documentation below it" do
    prose = "# frozen_string_literal: true\n\nmodule Shelf\n  # These are generated by nodes.\n  Fragment = 1\nend\n"
    late = "require \"shelf\"\n# DO NOT EDIT\n"
    project(["shelf.gemspec", ""], ["lib/shelf/fragment.rb", prose], ["lib/shelf/late.rb", late]) do |root|
      expect(described_class.new(root, {}).overlay).not_to(have_key("AllCops"))
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

  # simple_form's lib/generators/simple_form/templates/config/initializers/simple_form.rb, refinerycms's ERB
  # `.rake` templates: files a generator copies into another project, which hashira and kimera skip too.
  it "keeps a generator's templates out, an engine's included, and nothing beside them" do
    paths = %w[
      lib/generators/shelf/templates/config/initializers/shelf.rb core/lib/generators/shelf/install/templates/a.rb
      lib/rails/generators/shelf/model/template/model.rb lib/templates/erb/scaffold/form.rb
      lib/generators/shelf/install_generator.rb lib/shelf/templates.rb lib/shelf/template/page.rb
    ]
    patterns = YAML.load_file(base, aliases: true).dig("AllCops", "Exclude")
    kept = paths.reject { |path| patterns.any? { File.fnmatch?(it, path, File::FNM_PATHNAME | File::FNM_EXTGLOB) } }
    expect(kept).to(eq(paths.last(3)))
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
    cops = %w[GoodMethodName RealWords NoComments NoHashAsObject NoTypeCheck NoClassMethodLogic FrozenState]
      .map { "Kata/#{it}" }
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

  # content-tagger's `Taxonomy.table_name_prefix`, support's `fields_for :time_constraint`, statesman's commit hook.
  it "leaves the names Rails calls by name to Rails, and still judges the words a project chose" do
    source = <<~RUBY
      module Taxonomy
        def self.table_name_prefix = "taxonomy_"

        class Hook
          def time_constraint_attributes=(value)
            @value = value
          end

          def customer_billing_address_attributes=(value)
            @value = value
          end

          def trigger_transactional_callbacks? = true
          def has_transactional_callbacks? = true
          def add_to_transaction(*) = nil
          def committed!(*) = nil
          def rolledback!(*) = nil
        end
      end
    RUBY
    path = "app/models/taxonomy.rb"
    found = project(["config/application.rb", ""], [path, source]) { judged(it, path) }
    expect(found).to(eq([[9, "Kata/GoodMethodName"]]))
  end

  def judged(root, path)
    cops = %w[NoClassMethodLogic GoodMethodName RealWords].map { RuboCop::Cop::Kata.const_get(it).new(profiled(root)) }
    parsed = RuboCop::ProcessedSource.from_file(File.join(root, path), 3.4)
    found = RuboCop::Cop::Commissioner.new(cops, [], raise_error: true).investigate(parsed).offenses
    found.map { [it.line, it.cop_name] }
  end

  def profiled(root)
    setting = YAML.load_file(described_class.new(root, {}).path, aliases: true)
    RuboCop::Config.new(setting, File.join(root, ".rubocop.yml"))
  end

  context "with the autocorrect allowlist" do
    let(:allowed) { entries.reject { it[1] == "held" }.map(&:first) }
    let(:held) { YAML.load_file("config/autocorrect.yml") }

    def shipped
      setting = "plugins:\n  - rubocop-kata\n\nAllCops:\n  TargetRubyVersion: 3.4\n"
      files = [["shelf.gemspec", ""], [".rspec", ""], ["config/application.rb", ""], [".rubocop.yml", setting]]
      project(*files) { RuboCop::ConfigStore.new.for_dir(it) }
    end

    def entries = File.readlines("data/autocorrect.txt", chomp: true).map { it.split(" ", 3) }

    def withheld = entries.select { it[1] == "held" }.map(&:first)

    def unsafe?(setting)
      switches = setting.values_at("SafeAutoCorrect", "Safe", "AutoCorrect")
      switches.include?(false) || switches.include?("disabled")
    end

    def eligible?(config, cop)
      cop.support_autocorrect? && config.cop_enabled?(cop.cop_name) && !unsafe?(config.for_cop(cop))
    end

    it "lists each correction once, in order" do
      names = entries.map(&:first)
      expect(names).to(eq(names.uniq.sort))
    end

    it "files every correction under layout, delimiter, equivalent or held, with a reason" do
      kinds = %w[layout delimiter equivalent held]
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

    # Opal's corelib reads Ruby locals from backtick JavaScript, which RuboCop cannot see.
    it "holds back every correction that renames, anonymises or forwards a parameter" do
      moved = %w[Lint/UnusedMethodArgument Lint/UnusedBlockArgument Style/ArgumentsForwarding Naming/BlockForwarding]
      expect(moved - withheld).to(be_empty)
    end

    it "holds back the rewrites a field test showed are not equivalent, and the ones that loop" do
      moved = %w[
        Style/Not Style/EmptyCaseCondition Style/OrAssignment Style/RedundantSelfAssignmentBranch Style/PerlBackrefs
        Style/IfInsideElse Style/CommentedKeyword Layout/HeredocIndentation Lint/AmbiguousOperatorPrecedence
        Lint/RedundantStringCoercion Style/RedundantInterpolationUnfreeze Style/TrailingUnderscoreVariable
      ]
      expect(moved - withheld).to(be_empty)
    end

    it "never holds back a correction it allows" do
      expect(held.select { |_, setting| unsafe?(setting) }.keys & allowed).to(be_empty)
    end

    it "holds back every correction kata runs that no corpus suite has proved" do
      config = shipped
      correcting = RuboCop::Cop::Registry.global.cops.select(&:support_autocorrect?).map(&:cop_name)
      loose = correcting.select { config.cop_enabled?(it) && !allowed.include?(it) && !unsafe?(config.for_cop(it)) }
      expect(loose).to(be_empty)
    end

    it "lets rubocop -a run every correction the allowlist names" do
      config = shipped
      known = allowed.filter_map { RuboCop::Cop::Registry.global.find_by_cop_name(it) }
      expect(known.reject { eligible?(config, it) }.map(&:cop_name)).to(be_empty)
    end
  end
end
