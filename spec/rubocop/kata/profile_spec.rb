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

  it "hands a gem that runs RSpec the shipped defaults unchanged" do
    project(["shelf.gemspec", ""], [".rspec", ""]) { expect(described_class.new(it, {}).path).to(eq(base)) }
  end

  it "adds the Rails setting, and leaves out packaging and RSpec, for a Rails app on Minitest" do
    project(["config/application.rb", ""]) do |root|
      off = { "Enabled" => false }
      expected = { "inherit_from" => [base, rails], "Packaging" => off, "RSpec" => off }
      expect(described_class.new(root, {}).overlay).to(eq(expected))
    end
  end

  it "reads RSpec from the lockfile when the project keeps no .rspec" do
    lock = "GEM\n  specs:\n    rspec-core (3.13.0)\n"
    project(["shelf.gemspec", ""], ["Gemfile.lock", lock]) { expect(described_class.new(it, {}).path).to(eq(base)) }
  end

  it "does not take a gem that merely depends on rspec-core for one that runs it" do
    lock = "GEM\n  specs:\n    rspec-expectations (3.13.0)\n      rspec-core (~> 3.13)\n"
    project(["shelf.gemspec", ""], ["gems.locked", lock]) do |root|
      expect(described_class.new(root, {}).overlay).to(include("RSpec" => { "Enabled" => false }))
    end
  end

  it "lets the plugin's options overrule what it detects" do
    project(["config/application.rb", ""], [".rspec", ""]) do |root|
      options = { "rails" => false, "packaging" => true, "rspec" => false }
      expected = { "inherit_from" => [base], "RSpec" => { "Enabled" => false } }
      expect(described_class.new(root, options).overlay).to(eq(expected))
    end
  end

  it "writes the overlay once, where RuboCop can load it, and hands back the same file" do
    project(["config/application.rb", ""]) do |root|
      profile = described_class.new(root, {})
      first = profile.path
      expect([YAML.load_file(first), profile.path]).to(eq([profile.overlay, first]))
    end
  end

  it "keeps the Rails setting to framework contracts and generated files" do
    setting = YAML.load_file(rails)
    names = setting.dig("Kata/GoodMethodName", "AllowedNames")
    expect([setting.keys, names.include?("default_url_options"), setting.dig("Kata/NoComments", "Exclude")])
      .to(eq([%w[inherit_mode Kata/GoodMethodName Kata/NoComments], true, %w[bin/**/* db/**/*]]))
  end
end
