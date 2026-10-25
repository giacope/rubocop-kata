# frozen_string_literal: true

RSpec.describe(RuboCop::Kata::Correction) do
  def flaw(original, corrected) = described_class.new(original, corrected).flaw

  it "passes quote swaps, joined or split adjacent literals and %w words, whose values stay" do
    original = "a = 'x' \\\n  'y'\nb = %w[c d]\nc = <<-TEXT\n  body\n  TEXT\nd = \"e\#{}f\"\n"
    corrected = "a = \"x\" \"y\"\nb = [\"c\", \"d\"]\nc = <<-TEXT\n  body\nTEXT\nd = \"e\#{}f\"\n"
    expect(flaw(original, corrected)).to(be_nil)
  end

  it "reads the text a single-string interpolation spells as text, as -a keeps a heredoc's trailing spaces" do
    original = "x = <<~TEXT\n  a  \n  b\nTEXT\n"
    expect(flaw(original, "x = <<~TEXT\n  a\#{'  '}\n  b\nTEXT\n")).to(be_nil)
  end

  it "passes a symbol written for a string's to_sym, and an empty string an interpolation drops" do
    original = "a = \"key\".to_sym\nb = \"\#{c ? d : ''}\"\n"
    expect(flaw(original, "a = :key\nb = \"\#{d if c}\"\n")).to(be_nil)
  end

  it "compares an interpolation as code, not as the text it may produce" do
    expect(flaw("a = \"<\#{b.to_s}>\"\n", "a = \"<\#{b}>\"\n")).to(be_nil)
  end

  it "joins an interpolated literal with the literal beside it" do
    expect(flaw("a = \"b\#{c}\" \\\n  \"d\"\n", "a = \"b\#{c}d\"\n")).to(be_nil)
  end

  it "passes a space moved across adjacent literals, whose joined value stays" do
    expect(flaw("a = \"x \" \\\n  \"y\"\n", "a = \"x\" \\\n  \" y\"\n")).to(be_nil)
  end

  # Adjacent literals are one frozen String; `+` builds a new, unfrozen one.
  it "reads a + or any other call between string literals as a call, not as the string adjacent literals join" do
    original = "a = 'b' \\\n  \"c\"\n"
    expect([flaw(original, "a = 'b' + \"c\"\n"), flaw(original, "a = \"b\".concat(\"c\")\n")])
      .to(eq(["changed the literal on line 1"] * 2))
  end

  it "reads an interpolation of several statements as code, even when the first is a string" do
    expect(flaw("a = \"\#{'p'; q}\"\n", "a = \"p\"\n")).to(eq("changed the literal on line 1"))
  end

  it "names the first line of an interpolated literal that spans several" do
    expect(flaw("a = 1\nb = \"\#{c}\n  d\"\n", "a = 1\nb = \"\#{c}\nd\"\n")).to(eq("changed the literal on line 2"))
  end

  it "reads a symbol key as a name, which Style/SuperArguments may drop with its argument" do
    expect(flaw("def a(b, c:) = super(b, c: c)\nd = { :e => 1 }\n", "def a(b, c:) = super\nd = { e: 1 }\n")).to(be_nil)
  end

  it "reads a string key as text" do
    expect(flaw("a = { \"b\n  c\" => 1 }\n", "a = { \"b\n    c\" => 1 }\n")).to(eq("changed the literal on line 1"))
  end

  it "says the correction made the file unparsable" do
    expect(flaw("def a = 1\n", "def a = \n")).to(eq("made it unparsable"))
  end

  it "judges nothing when the original does not parse either" do
    expect(flaw("def a(\n", "def a(\n  \n")).to(be_nil)
  end

  it "names the line of a string whose content a correction changed" do
    original = "a = 1\nb = \"select *   \nfrom t\"\n"
    expect(flaw(original, "a = 1\nb = \"select *\nfrom t\"\n")).to(eq("changed the literal on line 2"))
  end

  it "names the occurrence a correction changed when the value repeats" do
    original = "a = /p\n  q/\nb = /p\n  q/\n"
    expect(flaw(original, "a = /p\n  q/\nb = /p\n    q/\n")).to(eq("changed the literal on line 3"))
  end

  it "says so when a correction only adds a literal" do
    expect(flaw("a = 1\n", "a = 1\nb = \"c\"\n")).to(eq("changed the literal on line 2"))
  end

  it "reads quoted symbols and x-strings too" do
    expect([flaw("a = :\"b\n\tc\"\n", "a = :\"b\n  c\"\n"), flaw("`a\n\tb`\n", "`a\n  b`\n")])
      .to(eq(["changed the literal on line 1"] * 2))
  end

  it "keeps the place of an interpolation, so text moved across it is a change" do
    expect(flaw("a = \"\#{b}c\"\n", "a = \"c\#{b}\"\n")).to(eq("changed the literal on line 1"))
  end

  it "reads a heredoc nested in another's interpolation in its own right" do
    original = "a = <<A\n\#{b.map { <<-B }.join}\nx\nB\nA\n"
    corrected = "a = <<A\n\#{b.map { <<-B }.join}\n  x\nB\nA\n"
    expect(flaw(original, corrected)).to(eq("changed the literal on line 2"))
  end

  it "reads the code interpolated into an adjacent literal" do
    original = "a = \"b\#{c(\"d  \ne\")}\" \"f\"\n"
    expect(flaw(original, "a = \"b\#{c(\"d\ne\")}\" \"f\"\n")).to(eq("changed the literal on line 1"))
  end
end
