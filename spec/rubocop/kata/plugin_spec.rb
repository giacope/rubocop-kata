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
