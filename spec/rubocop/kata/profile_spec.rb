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

  it "keeps the Rails setting to framework contracts and generated files" do
    setting = YAML.load_file(rails)
    names = setting.dig("Kata/GoodMethodName", "AllowedNames")
    expect([setting.keys, names.include?("default_url_options"), setting.dig("Kata/NoComments", "Exclude")])
      .to(eq([%w[Kata/GoodMethodName Kata/NoComments Kata/NoHashAsObject], true, %w[bin/**/* db/**/*]]))
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
