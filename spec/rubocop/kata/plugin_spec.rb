# frozen_string_literal: true

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

  it "hands RuboCop the shipped defaults" do
    path = plugin.rules(LintRoller::Context.new(engine: :rubocop)).value
    expect(path.realpath).to(eq(Pathname.new("config/default.yml").realpath))
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
      unsafe = %w[Style/EmptyClassDefinition Style/Proc].map { config.for_cop(it)["SafeAutoCorrect"] }
      expect(unsafe).to(eq([false, false]))
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

  it "leaves a top-level class in a Zeitwerk root to Rails, and nowhere else" do
    paths = %w[
      app/models/account.rb app/models/concerns/archivable.rb app/jobs/sweep_job.rb
      app/models/billing/invoice.rb lib/invoice.rb
    ]
    config = RuboCop::Config.new(shipped.slice("Kata/ClassInModule"), "/app/.rubocop.yml")
    cop = RuboCop::Cop::Kata::ClassInModule.new(config)
    expect(paths.map { cop.relevant_file?(File.join("/app", it)) }).to(eq([false, false, false, true, true]))
  end
end
