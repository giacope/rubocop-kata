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
    shipped = YAML.load_file("config/default.yml").select { |key, value| key.include?("/") && value.is_a?(Hash) }
    tuned = shipped.reject { |_, settings| settings.key?("Enabled") }.keys
    effective { |config| expect(tuned.select { config.for_cop(it)["Enabled"] == false }).to(be_empty) }
  end

  it "keeps the parameter limit it advertises" do
    effective do |config|
      expect(config.for_cop("Metrics/ParameterLists").slice("Enabled", "Max")).to(eq("Enabled" => true, "Max" => 4))
    end
  end
end
