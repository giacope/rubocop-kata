# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Kata::RealWords, :config) do
  let(:ruby_version) { 3.4 }
  let(:cop_config) do
    {
      "BannedWords" => YAML.load_file("config/default.yml", aliases: true).fetch("Kata/RealWords").fetch("BannedWords"),
      "Terms" => %w[],
      "Vocabulary" => %w[],
      "AllowedNames" => %w[],
      "NodeCallbacks" => false
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

  # once-campfire: svg, png and jpeg were words, gif and webp were not, and
  # neither was the browser it sniffs for.
  it "knows the media formats, browsers and initialisms a web app names" do
    expect_no_offenses(<<~RUBY)
      def firefox? = gif_frames + webp_size + mp4_track + webm_track + avif_size + heic_size
      qr_code = pwa_install
    RUBY
  end

  it "flags a clipping whichever dictionary lists it, and names the word" do
    expect_offense(<<~RUBY)
      def call(args, opts, src, cmd) = [args, opts, src, cmd]
               ^^^^ `args` is an abbreviation of `arguments`; spell the word out.
                     ^^^^ `opts` is an abbreviation of `options`; spell the word out.
                           ^^^ `src` is an abbreviation of `source`; spell the word out.
                                ^^^ `cmd` is an abbreviation of `command`; spell the word out.
      def run(str, req, resp, conn) = [str, req, resp, conn]
              ^^^ `str` is an abbreviation of `string`; spell the word out.
                   ^^^ `req` is an abbreviation of `request`; spell the word out.
                        ^^^^ `resp` is an abbreviation of `response`; spell the word out.
                              ^^^^ `conn` is an abbreviation of `connection`; spell the word out.
      msgs = []
      ^^^^ `msgs` is an abbreviation of `messages`; spell the word out.
      utils = []
      ^^^^^ `utils` is an abbreviation of `utilities`; spell the word out.
    RUBY
  end

  it "names every reading of a clipping that stands for more than one word" do
    expect_offense(<<~RUBY)
      dist = 1
      ^^^^ `dist` is an abbreviation of `distance` or `distribution`; spell the word out.
    RUBY
  end

  it "follows a word through two derivations: a plural agent noun, a -y adjective" do
    expect_no_offenses(<<~RUBY)
      matchers = satisfiable = verifiable = 1
    RUBY
  end

  it "knows the initialisms and technology names large codebases name" do
    expect_no_offenses(<<~RUBY)
      graphql = imap = hmac = ai = llm = sso = 1
      decrypt = rollup = omniauth = openai = js = apk = 2
    RUBY
  end

  it "names a placeholder for what it is" do
    expect_offense(<<~RUBY)
      foo = 1
      ^^^ `foo` is a placeholder; name what it holds.
    RUBY
  end

  it "keeps the platform's own names, and English words that end like a clipping's plural" do
    expect_no_offenses(<<~RUBY)
      def call(env, params, io, dir, regexp, stdout) = [env, params, io, dir, regexp, stdout]
      lens = []
      bars = []
    RUBY
  end

  context "with the shipped defaults" do
    let(:cop_config) { RuboCop::ConfigLoader.default_configuration.for_cop("Kata/RealWords").merge("Vocabulary" => []) }

    it "allows the conversion protocol Ruby calls by name" do
      expect_no_offenses(<<~RUBY)
        def to_str = "x"
        def to_sym = :x
        def to_ary = []
        def to_int = 1
      RUBY
    end

    it "still flags the clipping elsewhere" do
      expect_offense(<<~RUBY)
        def str = "x"
            ^^^ `str` is an abbreviation of `string`; spell the word out.
      RUBY
    end
  end

  it "flags abbreviations, including ones that happen to be dictionary words" do
    expect_offense(<<~RUBY)
      def cfg
          ^^^ `cfg` is an abbreviation of `configuration`; spell the word out.
      end
      def err
          ^^^ `err` is an abbreviation of `error`; spell the word out.
      end
      idx = 1
      ^^^ `idx` is an abbreviation of `index`; spell the word out.
    RUBY
  end

  it "names the offending segment inside an underscored name" do
    expect_offense(<<~RUBY)
      error_cnt = 1
      ^^^^^^^^^ `cnt` (in `error_cnt`) is an abbreviation of `count`; spell the word out.
      def report_msg
          ^^^^^^^^^^ `msg` (in `report_msg`) is an abbreviation of `message`; spell the word out.
      end
    RUBY
  end

  it "strips sigils, memo underscores, and predicate, bang, and setter suffixes" do
    expect_offense(<<~RUBY)
      @ctx = 1
      ^^^^ `@ctx` is an abbreviation of `context`; spell the word out.
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
      zq2 = 1
      ^^^ `zq2` is not in the dictionary — restore the underscore between smashed words, spell the abbreviation out, or add it to `Terms` if it is one domain term here.
    RUBY
  end

  it "reads a single letter with a trailing number as a single letter" do
    expect_no_offenses(<<~RUBY)
      v2 = 1
      x10_count = 2
    RUBY
  end

  context "with anonymous parameters, which need Ruby 3.1" do
    let(:ruby_version) { 3.4 }

    it "checks rest, keyword-rest, and block parameters, and skips anonymous ones" do
      expect_offense(<<~RUBY)
        def run(*filelist, **classbody, &sourcecount)
                 ^^^^^^^^ `filelist` is not in the dictionary — restore the underscore between smashed words, spell the abbreviation out, or add it to `Terms` if it is one domain term here.
                             ^^^^^^^^^ `classbody` is not in the dictionary — restore the underscore between smashed words, spell the abbreviation out, or add it to `Terms` if it is one domain term here.
                                         ^^^^^^^^^^^ `sourcecount` is not in the dictionary — restore the underscore between smashed words, spell the abbreviation out, or add it to `Terms` if it is one domain term here.
        end
        def pass(*, **, &)
        end
      RUBY
    end
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

  it "reads names the attr macros, define_method and alias mint" do
    expect_offense(<<~RUBY)
      attr_reader :usr
                  ^^^^ `usr` is an abbreviation of `user`; spell the word out.
      define_method(:matchingids) { [] }
                    ^^^^^^^^^^^^ `matchingids` is not in the dictionary — restore the underscore between smashed words, spell the abbreviation out, or add it to `Terms` if it is one domain term here.
      alias cfg name
            ^^^ `cfg` is an abbreviation of `configuration`; spell the word out.
    RUBY
  end

  it "follows a clipping into its plural, when the plural is no word itself" do
    expect_offense(<<~RUBY)
      ptrs = []
      ^^^^ `ptrs` is an abbreviation of `pointer`; spell the word out.
    RUBY
  end

  # vita-min, whitehall and alaveteli: British and Commonwealth codebases spell
  # organisation, offence and colour the way their authors do.
  it "knows British and Commonwealth spellings and their derivations" do
    expect_no_offenses(<<~RUBY)
      organisation = offence = colour = behaviour = neighbour = 1
      sanitised = authorised = labelled = metres = programme = analyse = 2
      centred = travelling = licence = personalisation = paediatric = 3
    RUBY
  end

  it "knows the cloud and government initialisms an infrastructure codebase names" do
    expect_no_offenses(<<~RUBY)
      uk_region = vpc_id = iam_role = acl_entry = arn = 1
    RUBY
  end

  it "still flags a smash of two British words" do
    expect_offense(<<~RUBY)
      colourcount = 1
      ^^^^^^^^^^^ `colourcount` is not in the dictionary — restore the underscore between smashed words, spell the abbreviation out, or add it to `Terms` if it is one domain term here.
    RUBY
  end

  context "with American spelling required" do
    let(:cop_config) do
      { "BannedWords" => [], "Terms" => [], "AllowedNames" => [], "Spelling" => "en-US" }
    end

    it "flags the British spelling of a word it knows in American" do
      expect_offense(<<~RUBY)
        organisation = color = 1
        ^^^^^^^^^^^^ `organisation` is not in the dictionary — restore the underscore between smashed words, spell the abbreviation out, or add it to `Terms` if it is one domain term here.
      RUBY
    end
  end

  context "with a project's own banned word" do
    let(:cop_config) { { "BannedWords" => %w[zap], "Terms" => [], "AllowedNames" => [] } }

    it "calls it an abbreviation without guessing the word" do
      expect_offense(<<~RUBY)
        zap = 1
        ^^^ `zap` is an abbreviation; spell the word out.
      RUBY
    end
  end

  it "knows en-GB nouns, networking and mail initialisms, and the words the corpus showed" do
    expect_no_offenses(<<~RUBY)
      def deliver(artefact, dependants, tcp, ipv6, cpu, dkim, bcc, jitter, uptime, heatmap, stylesheet) = nil
    RUBY
  end

  context "with the project's vocabulary" do
    include TabledCop

    let(:cop_config) do
      words = %w[kata lvasgn cref jsonify]
      { "Terms" => %w[frob], "Vocabulary" => words, "AllowedNames" => [], "NodeCallbacks" => true }
    end

    it "takes the project's name and the parser's node types for words" do
      expect_no_offenses(<<~RUBY)
        def on_lvasgn(node) = node
        kata = 1
      RUBY
    end

    # zeitwerk: `autoloaded`, `crefs`; rubocop: `autocorrected`; opal: `swapcased`.
    it "inflects every word it accepts, where no dictionary spells the forms" do
      expect_no_offenses(<<~RUBY)
        autoloaded = autoloading = autocorrected = swapcased = swapcasing = decrypted = favorited = paywalled = 1
        crefed = kataing = jsonified = frobbed = chmodded = chmodding = gzipping = evented = blocklisted = 1
      RUBY
    end

    # helpy `submited`, opal `embeded`, homeland `readed`/`logined`, faker `splitted`.
    # The dictionary spells `making` and `splitting`; `checkout` and `layoff` inflect as a phrase.
    it "still reads every misspelt form as a typo" do
      typos = %w[maked checkouted addoned dropdowned takeovered layoffed arged]
      expect(offenses(typos.map { "#{it} = 1" }.join("\n")).map { it.message[/`(\w+)`/, 1] }).to(eq(typos))
    end

    it "still reads a misspelt form as a typo where the dictionary spells the word's own" do
      expect_offense(<<~RUBY)
        submited = embeded = readed = logined = splitted = setuped = 1
        ^^^^^^^^ `submited` is not in the dictionary — restore the underscore between smashed words, spell the abbreviation out, or add it to `Terms` if it is one domain term here.
                   ^^^^^^^ `embeded` is not in the dictionary — restore the underscore between smashed words, spell the abbreviation out, or add it to `Terms` if it is one domain term here.
                             ^^^^^^ `readed` is not in the dictionary — restore the underscore between smashed words, spell the abbreviation out, or add it to `Terms` if it is one domain term here.
                                      ^^^^^^^ `logined` is not in the dictionary — restore the underscore between smashed words, spell the abbreviation out, or add it to `Terms` if it is one domain term here.
                                                ^^^^^^^^ `splitted` is not in the dictionary — restore the underscore between smashed words, spell the abbreviation out, or add it to `Terms` if it is one domain term here.
                                                           ^^^^^^^ `setuped` is not in the dictionary — restore the underscore between smashed words, spell the abbreviation out, or add it to `Terms` if it is one domain term here.
      RUBY
    end

    # rubocop's cops answer `on_str` and `on_op_asgn`, which RuboCop calls by the node's type.
    it "leaves a node callback to the parser's spelling, and bans the clipping elsewhere" do
      expect_offense(<<~RUBY)
        def on_str(node) = node
        def on_op_asgn(node) = node
        def on_strs(node) = node
            ^^^^^^^ `strs` (in `on_strs`) is an abbreviation of `string`; spell the word out.
        str = 1
        ^^^ `str` is an abbreviation of `string`; spell the word out.
      RUBY
    end
  end

  it "reads a node callback's name as any other where the project speaks no parser" do
    expect_offense(<<~RUBY)
      def on_str(node) = node
          ^^^^^^ `str` (in `on_str`) is an abbreviation of `string`; spell the word out.
    RUBY
  end

  it "leaves a method that calls super to its ancestor's name" do
    expect_no_offenses(<<~RUBY)
      def visit_dstr(node) = endpoint(node) { super }
    RUBY
  end

  context "with the project's library" do
    include TabledCop

    let(:root) { Dir.mktmpdir("kata-words") }
    let(:cop) do
      shipped = { "Kata/RealWords" => { "Vocabulary" => [], "OwnedPaths" => ["lib/**/*.rb"] } }
      described_class.new(RuboCop::Config.new(shipped, File.join(root, ".rubocop.yml")))
    end

    before do
      FileUtils.mkdir_p(File.join(root, "lib"))
      File.write(File.join(root, "lib", "walk.rb"), "class Walk\n  def visit(node) = node.dstr_parts\nend\n")
    end

    after { FileUtils.rm_rf(root) }

    it "leaves a stand-in for a message the project sends but never defines to the caller's name" do
      expect(offenses("def dstr_parts = 1\ndef dstr_count = 2\n").map(&:line)).to(eq([2]))
    end
  end
end
