# frozen_string_literal: true

RSpec.describe(RuboCop::Kata::Elegant::MonotonicIndents) do
  include TabledCop

  let(:cop) { described_class.new(RuboCop::Config.new) }

  # opal's corelib writes JavaScript inside `%x{}`; a shell script reads the same.
  it "leaves the lines of an x-string to the language they are written in, and judges the code around it" do
    shell = "def run\n  %x{\n    if [ -d dir ]; then\n          tar -czf backup.tgz dir\n    fi\n  }\n"
    source = "#{shell}  `ls\n        -la`\nend\ndef note\n      1\nend\n"
    expect(offenses(source).map(&:line)).to(eq([11]))
  end

  # strong_migrations' error messages: each message's text starts at column 0, the next key sits under the last.
  it "measures the line after a multi-line string that starts its line from the code before the string" do
    messages = "module Demo\n  MESSAGES = {\n    add_column:\n\"Adding a column\nrewrites it.\nend\",\n\n    " \
      "add_index: \"x\"\n  }\nend\n"
    expect(offenses(messages)).to(be_empty)
  end

  # transition's SQL in `.joins('...')`, mechanize's multi-line regexp.
  it "measures the line after a multi-line literal opened mid-line from the line that opens it" do
    sql = "def scope\n  select(\"x\")\n    .joins('\n  INNER JOIN sites\n')\n      .group(\"id\")\n      " \
      ".where(%r{\na\n}x)\nend\n"
    expect(offenses(sql)).to(be_empty)
  end

  it "still measures code lines, a one-line string at column 0, strings joined by a backslash and heredocs alike" do
    source = "def run\n  x = 1\n      y = 2\n  z = \"a\" \\\n        \"b\"\nend\nM = {\n  a:\n\"one\",\n    b: 2\n}\n" \
      "def text\n  <<~TEXT\n    a\n  TEXT\n      .strip\nend\n"
    expect(offenses(source).map(&:line)).to(eq([3, 5, 10, 16]))
  end

  it "reads a file of comments alone, which has no tree" do
    expect(offenses("# empty\n")).to(be_empty)
  end

  context "with rubocop-elegant's own class" do
    let(:cop) { RuboCop::Cop::Elegant::MonotonicIndents.new(RuboCop::Config.new) }

    it "reads as it ships, while RuboCop runs kata's class under its name", :aggregate_failures do
      source = "def run\n  %x{\n    if [ -d dir ]; then\n          tar -czf backup.tgz dir\n    fi\n  }\nend\n"
      expect(offenses(source).map(&:line)).to(eq([4]))
      expect(RuboCop::Cop::Registry.global.cops.select { it.cop_name == cop.cop_name }).to(eq([described_class]))
    end
  end
end
