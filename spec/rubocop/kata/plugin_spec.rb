# frozen_string_literal: true

RSpec.describe(RuboCop::Kata::Plugin) do
  let(:plugin) { described_class.new }

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
end
