# frozen_string_literal: true

require "tmpdir"

RSpec.describe(RuboCop::Kata::Plugin) do
  let(:plugin) { described_class.new }

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
    shipped = YAML.load_file("config/default.yml", aliases: true).select { |key, value| key.include?("/") && value.is_a?(Hash) }
    tuned = shipped.reject { |_, settings| settings.key?("Enabled") }.keys
    effective { |config| expect(tuned.select { config.for_cop(it)["Enabled"] == false }).to(be_empty) }
  end

  it "keeps the parameter limit it advertises" do
    effective do |config|
      expect(config.for_cop("Metrics/ParameterLists").slice("Enabled", "Max")).to(eq("Enabled" => true, "Max" => 4))
    end
  end

  it "accepts a module, a class, or a compact namespace, as the README says" do
    effective do |config|
      expect(config.for_cop("Elegant/NoClassInModule")["Enabled"]).to(be(false))
      expect(config.for_cop("Kata/ClassInModule")["Enabled"]).to(be(true))
    end
  end

  it "leaves a top-level class in a Zeitwerk root to Rails, and nowhere else" do
    Dir.mktmpdir("kata-config") do |root|
      shipped = YAML.load_file("config/default.yml", aliases: true).slice("Kata/ClassInModule")
      cop = RuboCop::Cop::Kata::ClassInModule.new(RuboCop::Config.new(shipped, File.join(root, ".rubocop.yml")))
      excluded = %w[app/models/account.rb app/models/concerns/archivable.rb app/jobs/sweep_job.rb]
      expect(excluded.map { cop.relevant_file?(File.join(root, it)) }).to(all(be(false)))
      expect(%w[app/models/billing/invoice.rb lib/invoice.rb].map { cop.relevant_file?(File.join(root, it)) }).to(all(be(true)))
    end
  end
end
