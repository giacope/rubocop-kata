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
end
