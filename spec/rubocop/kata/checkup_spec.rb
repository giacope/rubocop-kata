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

  let(:switched_off) do
    ".rubocop.yml:5: `DisabledByDefault: true` leaves 25 of kata's 26 cops off: RuboCop runs only the cops the " \
      "project's files enable by name; enable each by name (`Kata/GoodMethodName:` with `Enabled: true`), or drop " \
      "the key.\n1 dead entry\n"
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

  # CocoaPods: a renamed cop read as "not enabled here", which hid the fix.
  it "names the cop a directive's renamed cop became" do
    source = "# frozen_string_literal: true\n\n# rubocop:disable Lint/StringConversionInInterpolation, Kata/Nothing\n"
    expected = [
      "sample.rb:3: the directive names `Lint/StringConversionInInterpolation`, which RuboCop renamed to " \
        "`Lint/RedundantStringCoercion`; the comment does nothing.",
      "sample.rb:3: the directive names `Kata/Nothing`, which is not enabled here; the comment does nothing."
    ]
    project("", source) do |root|
      expect(report(root).first.lines.grep(/directive/).map { it.strip.delete_prefix("#{root}/") }).to(eq(expected))
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
    source = "# frozen_string_literal: true\n\n# rubocop:disable Kata/GoodClassName -- Avo resolves it\n" \
      "class Fetcher\nend\n# rubocop:enable Kata/GoodClassName\n"
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

  def tree(files)
    Dir.mktmpdir("kata-checkup") do |root|
      files.each { |path, text| File.write(File.join(root, path), text) }
      yield(root)
    end
  end

  it "reads the files .rubocop.yml inherits, the todo file among them" do
    tree(
      ".rubocop.yml" => "inherit_from:\n  - .rubocop_todo.yml\n\nplugins:\n  - rubocop-kata\n",
      ".rubocop_todo.yml" => "inherit_from: base.yml\n\nElegant/GoodMethodName:\n  Exclude:\n    - a.rb\n",
      "base.yml" => "\n\nElegant/GoodVariableName:\n  Exclude:\n    - a.rb\n"
    ) do |root|
      expect(report(root)).to(
        match([include(".rubocop_todo.yml:3: `Elegant/GoodMethodName`", "base.yml:3: `Elegant/GoodVariableName`"), 1])
      )
    end
  end

  it "keeps quiet about an inherited file that disables the cop itself" do
    tree(
      ".rubocop.yml" => "inherit_from: .rubocop_todo.yml\n\nplugins:\n  - rubocop-kata\n",
      ".rubocop_todo.yml" => "Elegant/GoodMethodName:\n  Enabled: false\n"
    ) { |root| expect(report(root).first).to(eq("clean\n")) }
  end

  # kimera's runtime: the directive Style/DirectiveScope asks for is a waiver too.
  it "lists a disable-next waiver with its reason" do
    source = "# frozen_string_literal: true\n\n# rubocop:disable-next Kata/FrozenState -- the switch mutants read\n" \
      "class Runtime\nend\n"
    project("", source) do |root|
      expect(report(root).first).to(include("sample.rb:3: disables `Kata/FrozenState` — the switch mutants read"))
    end
  end

  it "counts the files it could not check in the plural" do
    project("", "def total(\n") do |root|
      File.write(File.join(root, "other.rb"), "def other(\n")
      expect(report(root).first).to(include("2 files not fully checked"))
    end
  end

  it "says which file it could not decode, instead of passing it silently" do
    project("", "# rubocop:enable Elegant/GoodMethodName\nVALUE = \"\xFF\"\n".b) do |root|
      noted = include("sample.rb: does not parse", "0 dead entries, 1 file not fully checked")
      expect(report(root)).to(match([noted, 1]))
    end
  end

  it "says which file it could not read, and why" do
    allow(RuboCop::ProcessedSource).to(
      receive(:from_file).and_wrap_original do |read, path, *rest, **options|
        raise(Errno::EACCES, "sample.rb\nmore") if File.basename(path) == "sample.rb"

        read.call(path, *rest, **options)
      end
    )
    project("") do |root|
      expect(report(root).first).to(include("sample.rb: not checked, Errno::EACCES: Permission denied - sample.rb.\n"))
    end
  end

  it "says which file does not parse, and as which Ruby" do
    project("", "# rubocop:disable Kata/GoodClassName -- generated\ndef total(\n") do |root|
      expect(report(root).first).to(include("sample.rb: does not parse as Ruby 2.7, the target version"))
    end
  end

  it "names a plugin the project needs and this Ruby cannot load, instead of a backtrace" do
    project("plugins:\n  - rubocop-kata\n  - rubocop-missing-plugin\n") do |root|
      output, status = report(root)
      expect([output.lines.first, status])
        .to(match([include("configuration does not load", "bundle exec rubocop-kata doctor"), 2]))
    end
  end

  it "counts a single inline disable" do
    source = "# frozen_string_literal: true\n\nVALUE = 1 # rubocop:disable Style/MutableConstant -- read only\n"
    project("", source) do |root|
      expect(report(root).first).to(include("clean\n1 inline disable, 0 without a reason\n"))
    end
  end

  it "says to rename a cop RuboCop renamed in the configuration" do
    project("Lint/StringConversionInInterpolation:\n  Enabled: true\n", "VALUE = 1\n") do |root|
      expect(report(root)).to(match([include("rename it in .rubocop.yml"), 2]))
    end
  end

  # cancancan: RuboCop applies `Naming/PredicateName:` to `Naming/PredicatePrefix`, with a warning.
  # RuboCop releases before the rename still know the cop by its old name, so the entry is live there.
  it "says to rename an entry for a cop RuboCop renamed and still applies, instead of calling it dead" do
    project("Naming/PredicateName:\n  Exclude:\n    - sample.rb\n") do |root|
      renamed = [
        ".rubocop.yml:4: `Naming/PredicateName` was renamed to `Naming/PredicatePrefix`; rename the entry.\n" \
          "0 dead entries, 1 entry to rename\n", 1
      ]
      expected = RuboCop::Cop::Registry.global.find_by_cop_name("Naming/PredicatePrefix") ? renamed : ["clean\n", 0]
      expect(silenced { report(root) }).to(eq(expected))
    end
  end

  # solid_cache, caxlsx, resque, ransack: RuboCop then runs only the cops a project's own files name.
  it "says when DisabledByDefault leaves kata's cops off, and how to turn them on" do
    project("AllCops:\n  DisabledByDefault: true\n\nKata/RealWords:\n  Enabled: true\n") do |root|
      expect(report(root)).to(eq([switched_off, 1]))
    end
  end

  it "keeps quiet about a kata cop the project switches off itself, without DisabledByDefault" do
    project("Kata/GoodClassName:\n  Enabled: false\n") { |root| expect(report(root).first).to(eq("clean\n")) }
  end

  it "names the configuration file when it cannot point at the line that sets DisabledByDefault" do
    project("AllCops: { DisabledByDefault: true }\n") do |root|
      expect(report(root).first).to(start_with(".rubocop.yml: `DisabledByDefault: true` leaves 26 of kata's 26 cops"))
    end
  end

  def silenced
    stderr = $stderr
    $stderr = StringIO.new
    yield
  ensure
    $stderr = stderr
  end

  it "lists every inline disable with its reason, and fails on the bare ones" do
    source = "# frozen_string_literal: true\n\n# rubocop:disable Kata/GoodClassName -- Avo resolves it by name\n" \
      "class Fetcher\nend\n# rubocop:enable Kata/GoodClassName\nVALUE = 1 # rubocop:disable Style/MutableConstant\n"
    listed = [
      "sample.rb:3: disables `Kata/GoodClassName` — Avo resolves it by name",
      "sample.rb:7: disables `Style/MutableConstant` — no reason given",
      "0 dead entries\n2 inline disables, 1 without a reason\n"
    ]
    project("", source) { |root| expect(report(root)).to(match([include(*listed), 1])) }
  end
end
