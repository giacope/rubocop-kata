# frozen_string_literal: true

require "rubocop/kata/plan"
require "tmpdir"

RSpec.describe(RuboCop::Kata::Plan) do
  def project(*sources)
    Dir.mktmpdir("kata-plan") do |root|
      File.write(File.join(root, ".rubocop.yml"), "plugins:\n  - rubocop-kata\n")
      sources.each_with_index { |text, index| File.write(File.join(root, "sample#{index}.rb"), text) }
      yield(root)
    end
  end

  def report(root)
    io = StringIO.new
    described_class.new(root, io: io).run.then { [io.string, it] }
  end

  it "reports nothing to do on a clean project", :aggregate_failures do
    project("# frozen_string_literal: true\n") do |root|
      output, status = report(root)
      expect(output).to(eq("clean\n"))
      expect(status).to(eq(0))
    end
  end

  it "buckets an offense under the stage its cop belongs to" do
    project("# frozen_string_literal: true\n\nclass Fetcher\nend\n") do |root|
      expect(report(root).first).to(match(%r{^naming\s+\d+\s+Kata/AgentNoun}))
    end
  end

  it "names structure as the stage to take first, ahead of naming" do
    source = "# frozen_string_literal: true\n\nclass Fetcher\n  def load\n    ENV.fetch(\"A\", nil)\n  end\nend\n"
    project(source) do |root|
      expect(report(root).first).to(include("next: structure"))
    end
  end

  it "says why structure comes first" do
    project("# frozen_string_literal: true\n\nENV.fetch(\"A\", nil)\n") do |root|
      expect(report(root).first).to(include("mint the names `naming` then prices"))
    end
  end

  it "falls back to the remaining cops when no kata stage has anything" do
    project("# frozen_string_literal: true\n\nclass Sample0\nend\n") do |root|
      expect(report(root).first).to(include("next: rest"))
    end
  end

  it "names the file carrying the most of the stage it picked" do
    thin = "# frozen_string_literal: true\n\nENV.fetch(\"A\", nil)\n"
    thick = "# frozen_string_literal: true\n\nENV.fetch(\"A\", nil)\nENV.fetch(\"B\", nil)\n"
    project(thin, thick) { |root| expect(report(root).first).to(include("densest: sample1.rb (2)")) }
  end

  it "returns non-zero while any offense stands" do
    project("# frozen_string_literal: true\n\nclass Fetcher\nend\n") do |root|
      expect(report(root).last).to(eq(1))
    end
  end
end
