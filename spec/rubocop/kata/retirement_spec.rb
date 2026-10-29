# frozen_string_literal: true

require "tmpdir"

RSpec.describe(RuboCop::Kata::Retirement) do
  def rules(text)
    Dir.mktmpdir("kata-retirement") do |root|
      path = File.join(root, "obsoletion.yml")
      File.write(path, text)
      yield(described_class.new([path]))
    end
  end

  let(:profile) do
    {
      "Style/DoubleCopDisableDirective" => { "SafeAutoCorrect" => false },
      "Layout/IndentHeredoc" => { "Enabled" => true },
      "Lint/CopDirectiveSyntax" => { "SafeAutoCorrect" => false },
      "AllCops" => { "NewCops" => "enable" }
    }
  end

  it "leaves out a cop the running RuboCop has removed or renamed, and keeps every other key" do
    removed = "removed:\n  Style/DoubleCopDisableDirective:\n    reason: superseded\n"
    rules("#{removed}renamed:\n  Layout/IndentHeredoc: Layout/HeredocIndentation\n") do |retirement|
      expect(retirement.kept(profile).keys).to(eq(%w[Lint/CopDirectiveSyntax AllCops]))
    end
  end

  it "keeps the whole profile when the running RuboCop has retired none of its cops" do
    rules("split:\n  Style/MethodMissing:\n    alternatives: []\n") do |retirement|
      expect(retirement.kept(profile)).to(eq(profile))
    end
  end

  it "reads the rules RuboCop itself checks configuration against" do
    names = described_class.new.kept({ "Lint/Eval" => {}, "Security/Eval" => {} }).keys
    expect(names).to(eq(%w[Security/Eval]))
  end
end
