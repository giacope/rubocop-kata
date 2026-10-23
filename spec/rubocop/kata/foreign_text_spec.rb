# frozen_string_literal: true

RSpec.describe(RuboCop::Kata::ForeignText) do
  include TabledCop

  let(:cop) { RuboCop::Cop::Elegant::MonotonicIndents.new(RuboCop::Config.new) }

  # opal's corelib writes JavaScript inside `%x{}`; a shell script reads the same.
  it "leaves the lines of an x-string to the language they are written in, and judges the code around it" do
    shell = "def run\n  %x{\n    if [ -d dir ]; then\n          tar -czf backup.tgz dir\n    fi\n  }\n"
    source = "#{shell}  `ls\n        -la`\nend\ndef note\n      1\nend\n"
    expect(offenses(source).map(&:line)).to(eq([11]))
  end

  it "reads a file of comments alone, which has no tree" do
    expect(offenses("# empty\n")).to(be_empty)
  end
end
