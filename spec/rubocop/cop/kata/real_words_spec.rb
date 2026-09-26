# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::RealWords, :config) do
  let(:cop_config) do
    {
      "BannedWords" => YAML.load_file("config/default.yml").fetch("Kata/RealWords").fetch("BannedWords"),
      "Terms" => %w[],
      "AllowedNames" => %w[]
    }
  end

  it "flags names smashed together from real words, with no word list to maintain" do
    expect_offense(<<~RUBY)
      def applyexcludes
          ^^^^^^^^^^^^^ `applyexcludes` is not in the dictionary — restore the underscore between smashed words, spell the abbreviation out, or add it to `Terms` if it is one domain term here.
      end
      def matchingids
          ^^^^^^^^^^^ `matchingids` is not in the dictionary — restore the underscore between smashed words, spell the abbreviation out, or add it to `Terms` if it is one domain term here.
      end
      def self.coveringtests(sourcecount)
               ^^^^^^^^^^^^^ `coveringtests` is not in the dictionary — restore the underscore between smashed words, spell the abbreviation out, or add it to `Terms` if it is one domain term here.
                             ^^^^^^^^^^^ `sourcecount` is not in the dictionary — restore the underscore between smashed words, spell the abbreviation out, or add it to `Terms` if it is one domain term here.
        classbody = sourcecount
        ^^^^^^^^^ `classbody` is not in the dictionary — restore the underscore between smashed words, spell the abbreviation out, or add it to `Terms` if it is one domain term here.
      end
    RUBY
  end

  it "knows inflected forms: comparatives, superlatives, and -ied pasts" do
    expect_no_offenses(<<~RUBY)
      deeper = 1
      newer = 2
      longest = 3
      earlier = 4
      denied = 5
      held = 6
    RUBY
  end

  it "knows software vocabulary from the vendored cspell dictionaries" do
    expect_no_offenses(<<~RUBY)
      def parse(argv)
        cwd = argv.first
        [stderr, klass, mutex, regex, repl, cwd]
      end
    RUBY
  end

  it "flags abbreviations, including ones that happen to be dictionary words" do
    expect_offense(<<~RUBY)
      def cfg
          ^^^ `cfg` is an abbreviation; spell the word out.
      end
      def err
          ^^^ `err` is an abbreviation; spell the word out.
      end
      idx = 1
      ^^^ `idx` is an abbreviation; spell the word out.
    RUBY
  end

  it "names the offending segment inside an underscored name" do
    expect_offense(<<~RUBY)
      error_cnt = 1
      ^^^^^^^^^ `cnt` (in `error_cnt`) is not in the dictionary — restore the underscore between smashed words, spell the abbreviation out, or add it to `Terms` if it is one domain term here.
      def report_msg
          ^^^^^^^^^^ `msg` (in `report_msg`) is an abbreviation; spell the word out.
      end
    RUBY
  end

  it "strips sigils, memo underscores, and predicate, bang, and setter suffixes" do
    expect_offense(<<~RUBY)
      @ctx = 1
      ^^^^ `@ctx` is an abbreviation; spell the word out.
      def harnesscritical?
          ^^^^^^^^^^^^^^^^ `harnesscritical?` is not in the dictionary — restore the underscore between smashed words, spell the abbreviation out, or add it to `Terms` if it is one domain term here.
      end
      def classbody=(value)
          ^^^^^^^^^^ `classbody=` is not in the dictionary — restore the underscore between smashed words, spell the abbreviation out, or add it to `Terms` if it is one domain term here.
      end
    RUBY
    expect_no_offenses(<<~RUBY)
      @_memo = 1
      @@count = 1
      $verbose = 1
      _unused = 1
      _ = 1
      def fresh?
      end
    RUBY
  end

  it "knows inflections, modern vocabulary, and trailing digits" do
    expect_no_offenses(<<~RUBY)
      def entries(deadlines)
        running = deadlines
        closed = running
        files = closed
      end
      def memoize(timestamp)
        json = timestamp
        base64 = json
      end
      def groupable?(whitespace)
        unparenthesized = whitespace
        rerun = unparenthesized
        rerun
      end
    RUBY
  end

  it "leaves underscored names to Kata/GoodMethodName as long as every segment is a word" do
    expect_no_offenses(<<~RUBY)
      def mutant_id
      end
      def covering_tests(apply_excludes)
      end
    RUBY
  end

  it "ignores operators and single-letter segments" do
    expect_no_offenses(<<~RUBY)
      def ==(other)
        x = other
        x
      end
      def [](index)
        to_s(index)
      end
    RUBY
  end

  context "with domain terms reviewed into the budget" do
    let(:cop_config) do
      { "BannedWords" => %w[err], "Terms" => %w[lvasgn err], "AllowedNames" => %w[] }
    end

    it "allows the terms, and lets `Terms` override `BannedWords`" do
      expect_no_offenses(<<~RUBY)
        def on_lvasgn(node)
          err = node
          err
        end
      RUBY
    end
  end

  context "with a protocol-dictated name in the escape hatch" do
    let(:cop_config) do
      { "BannedWords" => %w[pos], "Terms" => %w[], "AllowedNames" => %w[pos] }
    end

    it "allows the listed name" do
      expect_no_offenses(<<~RUBY)
        def pos
        end
      RUBY
    end
  end

  it "checks class and global variables and every argument kind" do
    expect_offense(<<~RUBY)
      def run(sourcecount = 1, classbody:, filelist: nil)
              ^^^^^^^^^^^ `sourcecount` is not in the dictionary — restore the underscore between smashed words, spell the abbreviation out, or add it to `Terms` if it is one domain term here.
                               ^^^^^^^^^ `classbody` is not in the dictionary — restore the underscore between smashed words, spell the abbreviation out, or add it to `Terms` if it is one domain term here.
                                           ^^^^^^^^ `filelist` is not in the dictionary — restore the underscore between smashed words, spell the abbreviation out, or add it to `Terms` if it is one domain term here.
        @@sourcecount = sourcecount
        ^^^^^^^^^^^^^ `@@sourcecount` is not in the dictionary — restore the underscore between smashed words, spell the abbreviation out, or add it to `Terms` if it is one domain term here.
        $classbody = classbody
        ^^^^^^^^^^ `$classbody` is not in the dictionary — restore the underscore between smashed words, spell the abbreviation out, or add it to `Terms` if it is one domain term here.
      end
    RUBY
  end

  it "flags a two-letter segment the dictionary does not know" do
    expect_offense(<<~RUBY)
      zq_count = 1
      ^^^^^^^^ `zq` (in `zq_count`) is not in the dictionary — restore the underscore between smashed words, spell the abbreviation out, or add it to `Terms` if it is one domain term here.
    RUBY
  end

  context "with a sigiled name whose bare form is in the escape hatch" do
    let(:cop_config) do
      { "BannedWords" => %w[pos], "Terms" => %w[], "AllowedNames" => %w[pos] }
    end

    it "allows the listed name behind its sigil" do
      expect_no_offenses(<<~RUBY)
        @pos = 1
      RUBY
    end
  end
end
