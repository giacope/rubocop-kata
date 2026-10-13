# frozen_string_literal: true

require "rubocop/kata/checkup"
require "tmpdir"

RSpec.describe(RuboCop::Kata::Checkup) do
  def project(config, source = "# frozen_string_literal: true\n")
    Dir.mktmpdir("kata-checkup") do |root|
      File.write(File.join(root, ".rubocop.yml"), "plugins:\n  - rubocop-kata\n\n#{config}")
      File.write(File.join(root, "sample.rb"), source)
      yield(root)
    end
  end

  def report(root)
    io = StringIO.new
    described_class.new(root, io: io).run.then { [io.string, it] }
  end

  it "reports an entry for a cop the inherited configuration disables", :aggregate_failures do
    project("Elegant/GoodMethodName:\n  AllowedNames:\n    - active=\n") do |root|
      output, status = report(root)
      expect(output).to(include("`Elegant/GoodMethodName` is disabled by the configuration this project inherits"))
      expect(status).to(eq(1))
    end
  end

  it "keeps quiet when the project disables the cop itself" do
    project("Elegant/GoodMethodName:\n  Enabled: false\n") do |root|
      expect(report(root).first).to(eq("clean\n"))
    end
  end

  it "keeps quiet about an entry that configures a running cop" do
    project("Kata/GoodClassName:\n  AllowedNames:\n    - Adapter\n") do |root|
      expect(report(root).first).to(eq("clean\n"))
    end
  end

  it "reports a directive naming a cop that is not enabled", :aggregate_failures do
    project("", "# frozen_string_literal: true\n\n# rubocop:enable Elegant/GoodMethodName\n") do |root|
      output, status = report(root)
      expect(output).to(include("the directive names `Elegant/GoodMethodName`, which is not enabled here"))
      expect(status).to(eq(1))
    end
  end

  it "reports directives for enabled cops excluded from the file" do
    config = "Kata/GoodClassName:\n  Exclude:\n    - sample.rb\n"
    source = "# frozen_string_literal: true\n\n# rubocop:disable Kata/GoodClassName\n"
    project(config, source) do |root|
      expect(report(root).first).to(include("the directive names `Kata/GoodClassName`, which is not enabled here"))
    end
  end

  it "reports directives for enabled cops whose include does not match the file" do
    config = "Kata/GoodClassName:\n  Include:\n    - other.rb\n"
    source = "# frozen_string_literal: true\n\n# rubocop:disable Kata/GoodClassName\n"
    project(config, source) do |root|
      expect(report(root).first).to(include("the directive names `Kata/GoodClassName`, which is not enabled here"))
    end
  end

  it "reads directives from comments, not from source that merely quotes one" do
    project("", "# frozen_string_literal: true\n\nTEXT = \"# rubocop:enable Elegant/GoodMethodName\"\n") do |root|
      expect(report(root).first).to(eq("clean\n"))
    end
  end

  it "counts what it found" do
    project("Elegant/GoodMethodName:\n  AllowedNames: []\nElegant/GoodVariableName:\n  AllowedNames: []\n") do |root|
      expect(report(root).first).to(end_with("2 dead entries\n"))
    end
  end

  it "returns zero for a project with nothing to report" do
    project("") { |root| expect(report(root).last).to(eq(0)) }
  end

  it "counts a single finding in the singular" do
    project("Elegant/GoodMethodName:\n  AllowedNames: []\n") do |root|
      expect(report(root).first).to(end_with("\n1 dead entry\n"))
    end
  end

  it "follows YAML aliases the way RuboCop does" do
    project("Elegant/GoodMethodName: &off\n  Enabled: false\nElegant/GoodVariableName:\n  <<: *off\n") do |root|
      expect(report(root).first).to(eq("clean\n"))
    end
  end

  it "keeps quiet about a directive naming a cop that runs on the file" do
    source = "# frozen_string_literal: true\n\n# rubocop:disable Kata/GoodClassName\nclass Fetcher\nend\n" \
      "# rubocop:enable Kata/GoodClassName\n"
    project("", source) { |root| expect(report(root).first).to(include("\nclean\n")) }
  end

  it "keeps quiet about a directive that names every cop at once" do
    project("", "# frozen_string_literal: true\n\n# rubocop:disable all\n") do |root|
      expect(report(root).first).not_to(include("not enabled here"))
    end
  end

  it "checks directives in a project that has no .rubocop.yml" do
    Dir.mktmpdir("kata-checkup") do |root|
      File.write(File.join(root, "sample.rb"), "# rubocop:enable Kata/Nothing\n")
      expect(report(root).first).to(include("the directive names `Kata/Nothing`, which is not enabled here"))
    end
  end

  it "reads the files .rubocop.yml inherits, the todo file among them", :aggregate_failures do
    Dir.mktmpdir("kata-checkup") do |root|
      File.write(File.join(root, ".rubocop.yml"), "inherit_from:\n  - .rubocop_todo.yml\n\nplugins:\n  - rubocop-kata\n")
      File.write(File.join(root, ".rubocop_todo.yml"), "inherit_from: base.yml\n\nElegant/GoodMethodName:\n  Exclude:\n    - a.rb\n")
      File.write(File.join(root, "base.yml"), "\n\nElegant/GoodVariableName:\n  Exclude:\n    - a.rb\n")
      output, status = report(root)
      expect(output).to(include(".rubocop_todo.yml:3: `Elegant/GoodMethodName` is disabled"))
      expect(output).to(include("base.yml:3: `Elegant/GoodVariableName` is disabled"))
      expect(status).to(eq(1))
    end
  end

  it "keeps quiet about an inherited file that disables the cop itself" do
    Dir.mktmpdir("kata-checkup") do |root|
      File.write(File.join(root, ".rubocop.yml"), "inherit_from: .rubocop_todo.yml\n\nplugins:\n  - rubocop-kata\n")
      File.write(File.join(root, ".rubocop_todo.yml"), "Elegant/GoodMethodName:\n  Enabled: false\n")
      expect(report(root).first).to(eq("clean\n"))
    end
  end

  it "says which file it could not decode, instead of passing it silently", :aggregate_failures do
    project("", "# rubocop:enable Elegant/GoodMethodName\nVALUE = \"\xFF\"\n".b) do |root|
      output, status = report(root)
      expect(output).to(include("sample.rb: does not parse"))
      expect(output).to(end_with("0 dead entries, 1 file not fully checked\n"))
      expect(status).to(eq(1))
    end
  end

  it "says which file it could not read, and why" do
    allow(RuboCop::ProcessedSource).to(receive(:from_file).and_raise(Errno::EACCES, "sample.rb\nmore"))
    project("") do |root|
      expect(report(root).first).to(include("sample.rb: not checked, Errno::EACCES: Permission denied - sample.rb.\n"))
    end
  end

  it "says which file does not parse" do
    project("", "# rubocop:disable Kata/GoodClassName -- generated\ndef total(\n") do |root|
      expect(report(root).first).to(include("sample.rb: does not parse"))
    end
  end

  it "lists every inline disable with its reason, and counts the bare ones", :aggregate_failures do
    source = "# frozen_string_literal: true\n\n# rubocop:disable Kata/GoodClassName -- Avo resolves it by name\n" \
      "class Fetcher\nend\n# rubocop:enable Kata/GoodClassName\nVALUE = 1 # rubocop:disable Style/MutableConstant\n"
    project("", source) do |root|
      output, status = report(root)
      expect(output).to(include("sample.rb:3: disables `Kata/GoodClassName` — Avo resolves it by name"))
      expect(output).to(include("sample.rb:7: disables `Style/MutableConstant` — no reason given"))
      expect(output).to(end_with("clean\n2 inline disables, 1 without a reason\n"))
      expect(status).to(eq(0))
    end
  end
end
