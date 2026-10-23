# Changelog

## [Unreleased]

- From the fourth field test, on `rubocop -a` (50 codebases, 14 suites):
  - `-a` renames, anonymises or forwards no parameter: `Lint/UnusedMethodArgument`,
    `Lint/UnusedBlockArgument`, `Style/ArgumentsForwarding` and
    `Naming/BlockForwarding` are `-A` only. Opal's corelib reads Ruby locals from
    backtick JavaScript, which RuboCop cannot see, so `-a` left Opal unable to
    boot; a renamed shadowing block parameter assigned the outer local; `*`
    inside a block with its own `|*|` does not parse; YARD's `@param` and
    `Method#parameters` changed.
  - `-A` only, too, the "equivalent" rewrites that are not: `Style/Not`
    (`not a < b` became `a >= b`), `Style/EmptyCaseCondition` (`if *LIST`),
    `Style/OrAssignment` and `Style/RedundantSelfAssignmentBranch` (a method's
    value changed), `Style/PerlBackrefs` (`pre_match` on nil),
    `Style/IfInsideElse` (dropped comments), `Lint/RedundantStringCoercion` (a
    private or non-String `to_s`), `Style/CommentedKeyword` (deletes the comment
    on an `end` line); and `Layout/HeredocIndentation` (`<<END` → `<<~END` ended
    rodauth's heredoc at an indented SQL `END`, and broke roda's nested
    heredocs) and `Lint/AmbiguousOperatorPrecedence` (loops with
    `Style/RedundantParentheses` on `Sequel.|(a, b & c)`).
    `data/autocorrect.txt` lists each as `held`, with what it broke.
  - `Lint/AssignmentInCondition` and `Lint/AmbiguousRange`, on the list but
    shipped unsafe by RuboCop, now run under `-a` (they add parentheses):
    `script/autocorrect` writes `SafeAutoCorrect: true` for a listed correction
    RuboCop marks unsafe, and a spec checks both directions against the
    effective configuration.
  - `-a` keeps a file as it was when its corrections would leave it
    unparsable or change the value of a string, heredoc, x-string, regexp or
    symbol literal, and says so on one stderr line (`rubocop-kata: kept
    lib/sql.rb as it was: -a would have changed the literal on line 4`). It
    caught `Layout/TrailingWhitespace` inside a multi-line string and
    `Layout/IndentationWidth`/`IndentationStyle` inside a multi-line regexp or
    quoted symbol. RuboCop 1.91 or later.
  - `Kata/PairedBrackets` never indents a line that starts inside a string,
    regexp, symbol or x-string that ends mid-line (travis-api's SQL gained two
    spaces).

- `Kata/JustifiedDirective` and `rubocop-kata doctor` read every directive
  that turns a cop off: `disable-next` and `todo-next` (RuboCop 1.92's
  Style/DirectiveScope asks for them), and a `push`/`next` with a `-Cop`.
- `Kata/GoodClassName` and `Kata/GoodModuleName` count a brand rubocop-rspec
  spells as one word (`RSpec`, `RuboCop`) as one concept: `RSpecSuite` is
  two, not three.

- From running kata bare on its own repo, hashira and kimera (self-hosting):
  - The project's own name is its vocabulary: `Kata/RealWords` takes the
    segments of the gemspec names and of a Rails application's module for
    words (`Vocabulary`, which kata fills), and a gem that depends on parser,
    rubocop-ast, rubocop or unparser speaks the parser's node types
    (`on_lvasgn`, `dstr`, `kwoptarg`, `str`, `arg`) and has
    `Lint/BooleanSymbol` off, where `:false` is a node type.
  - A method that calls `super` keeps its ancestor's name, and a stand-in for
    a message the project's owned code sends but never defines keeps the
    caller's (a spec double of ActiveSupport's `get_callbacks`): in
    `Kata/GoodMethodName`, `Kata/RealWords` and `Kata/BuilderNoun`.
  - `Kata/EnvDiscipline` and `Kata/ClockDiscipline` take code outside every
    class, module and method for a script's boot layer.
  - `Kata/NoRedundantVariable` keeps a value that spans several lines (a
    heredoc's too) and a regexp under a name: both are explanatory variables.
  - `RSpec/SpecFilePathFormat` spells a project constant that embeds `RSpec`
    or `RuboCop` the way the brand is spelled (`RSpecAdapter` is
    `rspec_adapter`, not `r_spec_adapter`).
  - `Style/FormatStringToken` leaves `expect_offense`'s `%{name}` template
    alone, and the ThreadSafety state cops skip the test suite, as
    MethodRedefinition and DirChdir already did.
  - `ThreadSafety/NewThread` is on in the Rails profile only: its advice
    (leave threads to the server or the job runner) is for application
    code, and a library or a CLI that waits on child processes owns its
    threads. `Naming/PredicateMethod` allows a runner's `run`, which answers
    a boolean by contract (Minitest.run).
  - Dictionary: `hotspot`, `ndjson`, `jsonl`, `sarif` and `vendored` are
    words, and `init` is no longer a clipping (it cannot be spelled out:
    `initialize` is Ruby's constructor).
  - The evaluation suite's snippets run under their own `.rubocop.yml`, so
    the checkout around them lends them no vocabulary.
  - kata holds itself to its defaults: a bare `.rubocop.yml` with no inline
    disable, no hashira baseline (every kind on but change_coupling), and a
    full mutation run with no survivor, no uncovered mutant and nothing
    ignored, gated in CI on every push to main.

- From a third field test on thirty more MIT codebases (rubygems, mail,
  liquid, rack, pry, concurrent-ruby, dependabot-core, devise, good_job,
  activeadmin, syntax_tree, reek and others):
  - `rubocop -a` broke liquid, rack, mail and rubygems, so a correction is
    now admitted by its structure, not by a green suite: it changes layout,
    delimiters or quotes (never string, heredoc or regexp content), or swaps
    syntax for an exact equivalent that resolves no name the project could
    define, flips no `==` receiver, merges no condition and moves no
    expression. Every entry of `data/autocorrect.txt` carries its category
    and reason; 49 corrections left `-a` (among them RescueStandardError,
    GuardClause, SoleNestedConditional, StderrPuts, ParenthesesAroundCondition,
    FetchEnvVar and Kata/NoRedundantVariable) and 21 layout and delimiter
    corrections joined it. `Style/StringLiterals` leaves `version.rb` alone,
    which gemspecs read with a regexp. Each break is an eval case.
  - `Kata/NoRedundantVariable` never inlines a parameter, a read that comes
    before the assignment (a loop that carries the value back), or into a
    safe-navigation argument, an `||=`/`&&=` value or a branch.
  - A `sorbet` profile: `T.let`, `T.cast`, `T.must`, `T.unsafe` and `T.bind`
    read as the value they wrap and `T.nilable`/`T::Array[]` as types in
    ConstructorDiscipline, NoHashAsObject, NoRedundantVariable and
    FrozenState.
  - `Kata/NoTypeCheck` resolves names lexically and owns a fully qualified
    name only when the project defines it with a body (good_job's
    `ActiveJob::Base`), lets the project's definitions win over the core
    inventory (rubygems' `Gem::Source`), reads `respond_to?` of a method
    Ruby's (or, in the Rails profile, Rails') public classes answer as a
    protocol (`data/protocols`, written by `script/protocols`), and reports
    `case`/`when`, `case`/`in`, `===`, `.class ==` and `.class.name ==`
    ladders over the project's classes.
  - `Kata/NoComments` attaches documentation to the next public definition:
    across a Sorbet `sig`, a bare `memoize` line and RDoc's `##` blank line,
    and above `attr_*`, `define_method` and public constants.
  - `Kata/FrozenState` follows constructor helpers across files through the
    project's superclasses, subclasses and mixins (liquid, concurrent-ruby),
    reports changing what an ivar holds after construction, and takes
    `Arbre#build` as a hook in the Rails profile.
  - Vendored code (`**/vendor/**`) and generated files (a `.rl`/`.y`/
    `.racc`/`.treetop`/`.rex` sibling, or a "generated by"/"do not edit"
    header) are excluded.
  - RSpec is detected from Gemfiles, gemspecs and spec files; a Rails engine
    from any library file; the project root is the directory of the
    `.rubocop.yml` that loads the plugin.
  - GoodClassName skips a wrapper whatever its superclass; GoodMethodName
    reports an overridden name once, reads a joint only between two words,
    and ships the atomic vocabulary (`compare_and_set`); GoodVariableName
    leaves `$VERBOSE` and the other predefined globals alone; RealWords
    knows `artefact`, `dependant`, `tcp`, `ipv6`, `dkim`, `jitter` and more.
  - NoHashAsObject reads a braced hash passed last as a hash; the Rails
    profile names ActionController, Devise and InheritedResources hooks and
    NoClassMethodLogic accepts Ransack's and Devise's class methods, and asks
    for a constant when a class method only returns a literal.
  - `doctor` fails on inline disables without a reason and says to rename a
    cop RuboCop renamed in `.rubocop.yml`.

- From a second field test on twenty more MIT codebases (vita-min,
  whitehall, Claim-for-Crown-Court-Defence, apply-for-teacher-training,
  camaleon-cms, rails, rouge, steep, rspec, capybara, CocoaPods, asciidoctor,
  tapioca and others). `rubocop -a` still changed behavior in five ways, so
  it is now an allowlist:
  - A correction runs under `-a` only when kata's corpora (Sequel, rouge,
    steep) ran it with their suites green. `data/autocorrect.txt` lists
    those corrections; `script/autocorrect` writes `config/autocorrect.yml`,
    which marks every other autocorrecting cop `SafeAutoCorrect: false`, and
    `eval/run` reports the listed ones no green suite ran. rouge and steep
    join the eval corpora with their suites.
  - Name-swapping corrections are `-A` by policy: `Style/FormatString`
    (`sprintf` → `format` inside rouge's formatters, which define their own
    `format`), `Style/ObjectThen` (`yield_self` → `then` on a receiver that
    defines `then`), `Lint/DeprecatedConstants` (steep's own `TRUE` and
    `FALSE` became literals), and `Lint/AmbiguousRegexpLiteral`, which dropped
    a paren and left vita-min unparsable.
  - `Kata/NoEmptyLinesInMethods` and `Kata/NoEmptyLinesInBlocks` replace
    their Elegant originals, which deleted blank lines inside heredocs and
    multi-line strings (steep's hover text, vita-min's and whitehall's
    templates). The block cop is excluded from `**/spec/**` and `**/test/**`
    too, where it looped against RSpec's layout cops (capybara).
  - `Kata/RealWords` accepts British and Commonwealth spellings (883
    offenses on 38 words in the UK-government apps) and cloud initialisms
    (`vpc`, `iam`, `acl`, `arn`); `Spelling: en-US` holds a codebase to
    American.
  - `Kata/NoTypeCheck` decides what is Ruby's from a shipped inventory of
    core, stdlib and gem constants (`data/core.txt`, from
    `script/inventory`), not from the constants RuboCop's own process had
    loaded, so a project's `Parser` or `AST` is judged the same on every
    machine; `respond_to?` on IO and reflection protocols (`read`, `rewind`,
    `path`, `superclass`) is duck typing. A constant assigned `Class.new`,
    `Module.new`, `Struct.new` or `Data.define` is the project's own type,
    in the file or in `OwnedPaths`, also when the value starts on the next
    line (kimera's `Shift::Doubt =` / `Class.new(Suspect) do` went
    unflagged).
  - `Kata/NoHashAsObject` exempts the rows of a constant array table (fog's
    flavors) and the mappings a `TableMethods` call takes; the Rails profile
    lists `enum`.
  - `Kata/NoComments` counts one offense per block of comment lines (rails
    had 51,198, one per line), and under `AllowDocumentation` keeps a block
    directly above a public class, module or method in any markup, not only
    one carrying a YARD tag.
  - `Kata/GoodClassName` skips a reopen that only nests classes and
    modules, so a class is judged once, where it is defined (CocoaPods'
    `Installer` was reported in 54 files).
  - `Kata/NoRedundantVariable` measures the first and last lines a
    multi-line value would land on before inlining it into an argument list.
  - The plugin finds the project root from the working directory upwards,
    takes a Rails engine (`lib/**/engine.rb` subclassing `Rails::Engine`) for
    Rails, and reads a gemspec one directory down (a monorepo) as a gem.
    Configuration layers merge deeply: lists add up and an upper layer's
    setting wins, where scalars used to be OR-ed.
  - The Rails profile allows Pundit's `permitted_attributes_for_<action>`.
  - `doctor` names the cop a renamed cop became instead of calling it "not
    enabled here".

- From a field test on ten MIT codebases larger than Fizzy (Chatwoot,
  Coursemology, Feedbin, Huginn, Human Essentials, fastlane, Sequel,
  graphql-ruby, YARD, ruby-lsp). Plain `rubocop -a` no longer changes what
  code does; it left Sequel unable to load and failing 350 of its 8,261
  tests, and corrupted ruby-lsp's 1,986 RBS signatures:
  - `NewCops` is `disable`, and the 184 pending cops kata wants are listed
    one by one: a RuboCop upgrade adds no autocorrect nobody reviewed.
    `Style/EmptyClassDefinition` (which turned `(E = Class.new(Error)).name`
    into a nil class body) and `Style/Proc` (`proc` in a `BasicObject`) run
    under `-A` only, as do eight corrections that broke Sequel's or
    ruby-lsp's files: `Style/SingleLineMethods` and `Style/EmptyMethod`
    (`def (@m.db).name() false end`), `Style/Lambda` (`lambda{|| 1}`),
    `Style/DefWithParentheses` (once `Layout/LineLength` has split the line),
    `Style/OperatorMethodCall` (`o.~(a: 1)`), `Performance/BindCall`
    (Sequel's `dataset.bind(...).call(...)`), `Style/CaseEquality`
    (`Array === proxy`) and `Lint/UselessNumericOperation` (`Sequel.**(1)`).
  - `Naming/RescuedExceptionsVariableName` keeps `PreferredName: error` but
    reports only: RuboCop renamed the variable inside the rescue clause and
    left `ensure` and later lines on the old name.
  - `Layout/LeadingCommentSpace` allows RBS (`#:`) and Steep annotations,
    which `Kata/NoComments` already keeps.
  - `Kata/PairedBrackets` moves a closer below the heredoc its line opens,
    where it moved it into the heredoc's body.
  - `Kata/NoComments` reads a magic comment as Ruby does, in any case and
    with dashes or underscores (`# frozen-string-literal: true`).
  - `Layout/EmptyLineBetweenDefs` is off: it loops against the Elegant
    blank-line cops wherever defs sit in a block or method body.
  - `Packaging/RequireHardcodingLib` is off: it raises on a file with the
    frozen-string-literal comment kata itself adds.
- Misreads from the same field test:
  - `Kata/GoodClassName`: an unknown `-er` word is a doer only on a verb
    stem, as its configuration said (`Instapaper`, `Kickstarter` pass);
    `data/actions.txt` adds the technology verbs WordNet lacks (`upsert`).
    A class under one of the new `EntitySuperclasses` (`ApplicationRecord`)
    is a record of a thing (`Manufacturer`), and one under a
    `ContractSuperclasses` entry (`RuboCop::Cop::Base`) is named by a
    contract. `Docker` joins `AllowedNames`.
  - `Kata/RealWords`: derivations apply twice (`matchers`, `satisfiable`),
    `graphql`, `imap`, `hmac`, `sso`, `ai`, `llm`, `decrypt` and other names
    are words, and a clipping with several readings names them all.
  - `Kata/NoClassMethodLogic`: a class method whose result is a new
    instance of its class is a constructor; `name`, `to_s`, `inspect`,
    `===`, `method_missing` and `respond_to_missing?` are Ruby's protocol.
  - `Kata/ConstructorDiscipline`: `+""` and `{}.compare_by_identity` are the
    object's own state, a parameter default is a seam, and a guard may raise
    through the project's `RaisingMethods`.
  - `Kata/FrozenState`: a hook a superclass's constructor calls is
    construction (`ConstructorHooks` for a superclass in another file);
    state set in a `define_method` block or by `instance_variable_set` on
    self is judged.
  - `Kata/NoSetter` reports a setter `define_method` mints.
  - `Kata/IoDiscipline` leaves a `p` given a block or no argument (Phlex).
  - `Kata/ClassInModule` asks for a refinement or a decorator when a file
    reopens a core class.
  - `Kata/CommandQuery` reads a guard's bang on a constant as a raise.
  - `Kata/NoOutputArgument` names `[]=` for `counts[word] += 1`.
  - `rubocop-kata doctor` names a plugin the project cannot load instead of
    printing a backtrace, and the Ruby a file failed to parse as.
- Design, under one rule: framework contracts are exempt, framework idioms
  are not.
  - `Kata/NoTypeCheck` is on, judging only the project's own types (defined
    in the file or under the new `OwnedPaths`) and `respond_to?` probes for
    methods the project defines.
  - `Kata/NoRedundantVariable` inlines only a local whose name says nothing
    its value does not, and never past `Layout/LineLength`: an explanatory
    variable stays.
  - `Kata/GoodMethodName` and `Kata/GoodVariableName` take
    `AllowedPatterns`; Prism's listener names ship as a contract.
  - The plugin reads the project: rubocop-packaging runs only in a gem,
    rubocop-rspec only where RSpec runs, and a Rails app gets
    `config/rails.yml` (the names Rails, Devise and Turbo dictate, and
    generated `bin/` and `db/` out of `Kata/NoComments`). Plugin options
    `rails:`, `packaging:` and `rspec:` overrule the detection. The profile
    is written as one file: RuboCop checks a file a plugin's configuration
    inherits against the cops it knows, and the oldest release kata supports
    knows fewer cops than kata lists.
  - Kata cops skip `.jbuilder` templates.
- Known upstream: `Naming/RescuedExceptionsVariableName` raises on
  `x = begin ... rescue => e ... end.size` whether or not it may correct, since
  RuboCop builds the correction to mark the offense correctable.

- Fixes found by running kata on 37signals' Campfire:
  - `Kata/RealWords` knows `gif`, `webp`, `mp4`, `webm`, `avif` and `heic`
    (`svg`, `png` and `jpeg` already passed), the browser `firefox`, and the
    initialisms `qr` and `pwa`, which a web app names. Campfire's
    `ApplicationPlatform#firefox?` was its last offense.
  - `Kata/NoRedundantVariable` no longer inlines a safe-navigation chain as
    a receiver. `type = image&.type` read as `type.in?(list)` became
    `image&.type.in?(list)`, whose `&.` skips the `in?` too, so a nil image
    answered nil where it answered false. It still reports the variable,
    and an argument (`baz(a&.b)`) or a safe receiver (`a&.b&.c`) still
    inlines.
  - `Kata/PairedBrackets` puts the step it adds after a line's indent, not
    before it. On a line `Kata/NoComments` deleted in the same `rubocop -A`
    pass, the step survived the deletion and pushed the next line two columns
    right.
  - `Kata/NoHashAsObject` exempts the rows of a lookup table a constant
    names, not only the table: Campfire's `TRANSLATIONS`, one hash per
    phrase keyed by locale, raised 13 offenses.
  - `Kata/GoodClassName` judges a test of a framework-resolved module by the
    module's subject: `MessagesHelperTest` is judged as `Messages`, as
    `Kata/GoodModuleName` judges `MessagesHelper`, where it was a doer.
  - `Kata/GoodClassName` judges a test as its subject when the subject's
    agent word is one a framework superclass hands down:
    `ScrubbingFormatter < Logger::Formatter` passed, and its
    `ScrubbingFormatterTest` was a doer. The superclass lives in the
    subject's file, out of the test's sight, so the new
    `FrameworkSuperclasses` (`Logger`, `Logger::Formatter`,
    `ActiveSupport::LogSubscriber`) say which words a subject inherits;
    `PaymentProcessorTest` is still a doer.
  - `Kata/ProsePlacement` reads a string literal holding bytes that are not
    valid text (`"\xFF"`) as no prose, where it raised.
  - `rubocop-kata plan` runs with kata's defaults beneath the project's own
    configuration. On a project that had not named the plugin, Kata cops
    ran with no configuration at all: `Kata/ProsePlacement`, off by default,
    reported 593 offenses on Campfire, and `Kata/ClassInModule` ignored the
    Zeitwerk roots.

- Six cops for objects that keep their state, their arguments and their
  answers, each measured before its default was chosen: an independent rater
  labelled up to 25 offenses per cop on faraday, rubygems.org, hashira and
  kimera (every label is in `eval/results/object_discipline_labels.json`),
  and a cop is on only if at least one in three is actionable.
  - `Kata/NoSetter` (on; 50 offenses, 14 of 25 actionable): `attr_writer`,
    `attr_accessor` and `def name=`. `[]=` passes.
  - `Kata/FrozenState` (on; 93, 18 of 25): an ivar assigned outside
    `initialize`, `initialize_copy` or a helper only those call. Memoization
    passes (`@x ||=`, `@x = ... unless @x`, `if @x.nil?`, `@x = @x || ...`,
    `defined?(@x)`), and Rails controllers, mailers and helpers are excluded.
  - `Kata/NoOutputArgument` (on; 75, 21 of 25): `<<`, `[]=`, `delete`,
    `merge!`, `sort!` and the other `MutatingMethods` on a method's own
    parameter. Splats, a parameter reassigned first, and the sinks in
    `AllowedNames` (`io`, `out`, `buffer`, Rack's `env`) pass.
  - `Kata/CommandQuery` (on; 10, 10 of 10): a `?` method that assigns an ivar
    (memoizing passes) or calls a `!` method on itself, its state or its
    parameters. A bang whose value the query reads (`policy!(...).show?`) is
    a lookup, and passes.
  - `Kata/NoTypeCheck` (off; 332, 1 of 25): `is_a?`, `kind_of?`,
    `instance_of?`, `respond_to?`, outside the boot layer and the bodies of
    `==`, `eql?`, `<=>`, `===`, `coerce` and `respond_to_missing?`. Most
    checks in real code test AST node classes another library owns or
    validate input at a boundary, which the call cannot tell apart.
  - `Kata/NoSingleton` (on; 4, 2 of 4): `include Singleton`, and a
    class-level method caching an instance (`@instance ||= new`). A cached
    value (`Set.new`, `Struct.new`; `AllowedConstructors`) passes.
- `Kata/NoClassMethodLogic` also reports a module of functions: the
  `module_function` or `extend self` that declares it (67 offenses, 23 of 25
  actionable). hashira and kimera, written to kata's rules, account for 64.
- kata's own code passes the new cops: `Checkup#files` and `Ledger#nodes`
  return what they collect instead of filling a parameter, `PairedBrackets`
  keys its string cache by the source, and the eval suite's threads return
  their results. A snippet case can `enable: true` a cop that ships off.

- `Kata/GoodMethodName` judges a hook name by the words behind its leading
  underscores: `_fork`, `_dump` and `__send` pass, where they were reported as
  having an empty segment.
- kata's own `lib` now reads under those limits. hashira's fragmentation
  check found 21 public methods spread over chains of one-line helpers;
  folding single-use helpers into their callers took `lib` from 255 methods
  averaging 2.65 lines to 206 averaging 3.17. In a blind pairwise review of
  the 9 refactors, both raters preferred the merge for Checkup, Plan,
  PairedBrackets and GoodMethodName, both preferred the original for
  NoComments, ConstructorDiscipline, Ledger and Inlining, and split on
  RealWords, which keeps its merge; the four losses went back to their
  named predicates. Under
  hashira's revised check, which no longer counts named predicates, findings
  go from 18 to 0, with NoComments and Ledger kept by a directive citing the
  review. Cases, corpora and the mutation score (100%) are unchanged.

- Methods may run to 10 lines and names may take two words. A blind
  readability study compared kimera and hashira, written to kata's rules,
  with rubocop, faraday and rubygems.org: two samples of 60 entry methods,
  two independent AI reviewers each, agreeing on 54 and 55 of 60 calls. Readers judged 14–16
  of 30 house-style items over-fragmented against 0–2 of 30 in the control,
  and scored readability about 3.0 against 4.0 and name clarity about 2.5
  against 4.1. House-style methods averaged 3.0 lines, the control 6.3.
  `Metrics/MethodLength` goes from 5 to RuboCop's 10, and logic density is
  bounded by the complexity cops at RuboCop's defaults instead of Elegant's:
  `AbcSize` 17, `CyclomaticComplexity` 7 and `PerceivedComplexity` 8.
  `Kata/GoodMethodName` and `Kata/GoodVariableName` allow two words by
  default, role words uncounted. Three or more words, chained actions,
  smashes and clippings still fail, and `MaxWords: 1` restores one word. The
  messages now say that three words, not two, mean a missing concept, and a
  segment the `Pattern` rejects gets its own message.

Measured with the new `eval/run`, which scores a checkout as users install it;
[eval/results](eval/results/README.md) has the full before/after. Snippet cases
under the shipped defaults pass 164 of 167, up from 83.

- `rubocop -a` no longer deletes comments. `Kata/NoComments` corrected as
  safe, so plain `-a` cut faraday's 1,068 comment lines to 61, YARD tags and
  all; its correction is unsafe now (`-a` keeps 1,067 of 1,068). It also keeps
  what code cannot say or a tool reads: blocks that cite a URL, an issue or
  pull request (`rails/rails#123`, `#123`), an RFC, a CVE or a GHSA; emacs and
  vim modelines (`# -*- coding: binary -*-` sets every literal's encoding);
  Steep, RBS, Standard, reek, kimera and hashira directives, RubyMine
  `language=`; and, by default now, YARD-documented blocks
  (`AllowDocumentation: true`). `AllowedPatterns` adds a tool's directives.
- `Kata/GoodClassName` and `Kata/GoodModuleName` read a doer from WordNet 3.0:
  a word is a doer when its dominant sense is the agent of the verb its stem
  names, so `Number`, `Layer`, `Letter`, `Corner`, `Matter`, `Order` and
  `Folder` are things. On 400 labelled names the rule's precision rises from
  0.75 to 0.99 (recall 0.98 → 0.94). `AllowedNames` shrinks from 45 entries,
  duplicated for modules, to 9 shared through a YAML anchor. Framework names
  are `ContractSuffixes`: the framework dictates the suffix, not the subject,
  so `UsersController` is judged as `Users` and `ReportBuilderJob` as
  `ReportBuilder`. A class inherits the agent word of the superclass that
  chose it (`ActionHandler < Avo::Actions::ActionHandler`). `Presenter`,
  `Notifier`, `Subscriber`, `Driver` and `Timer` are no longer allowed: no
  framework resolves a class by them. A suggestion never names the class
  itself (`Liar` suggested `Liar`).
- `Kata/RealWords` prices every clipping the same, whichever dictionary lists
  it: `args`, `opts`, `src`, `cmd`, `impl`, `util`, `calc`, `func` now fail
  beside `str`, `req`, `resp` and `conn`, and the message names the word.
  `foo`, `baz` and `qux` are placeholders. The platform's own spellings pass
  (`env`, `params`, `attr`, `io`, `regexp`, `stdout`), and so does the
  conversion protocol (`to_str`, `to_sym`). The 123 reviewed clippings live in
  `data/clippings.txt`; `BannedWords` starts empty.
- `Kata/GoodMethodName` and `Kata/RealWords` price the names `attr_*`,
  `define_method`, `alias_method` and `alias` mint.
- `Kata/ClockDiscipline` accepts a parameter default as the seam, as
  `Kata/EnvDiscipline` does (`def stamp(now: Time.now)`), and catches
  `Time.zone.now`, `Date.current`, `Date.yesterday`, `Time.new` and
  `Process.clock_gettime`.
- `Kata/ConstructorDiscipline` allows shaping an argument (`Array(x)`,
  `Integer(port)`, `to_*`, `dup`) and the object's own lock or empty
  collection (`Mutex.new`, `Set.new`); `SecureRandom.uuid` stays flagged.
  `Kata/NoClassMethodLogic` allows `load`/`dump`, `_load`, `json_create`,
  `new` and `[]`. `Kata/NoHashAsObject` allows the hash `to_h` and `as_json`
  return. `Kata/NoBooleanFlag` allows `exit(false)`.
- `Kata/ClassInModule` excludes files directly in a Zeitwerk root
  (`app/models/account.rb`), and `Elegant/NoClassInModule` is off: together
  they accepted only `class A::B`, while the README promised a module, a
  class, or a compact namespace.
- New `Kata/JustifiedDirective` replaces the ban on inline disables: a
  `rubocop:disable` must say why after `--`, so a false positive costs one
  reviewed line, not a per-file `Exclude`.
- `Kata/PairedBrackets` corrects to the indent the Layout cops expect (its own
  spec expected a nested argument at its parent's column) and leaves block
  parameters with their brace. Ten core Layout cops are back on; the four that
  loop against Elegant's no-blank-lines rule stay off.
- `Naming/MemoizedInstanceVariableName` no longer corrects: renaming the ivar
  in one method broke 25 of faraday's specs under `-A` (now 0).
  `Metrics/AbcSize` returns to 17, pricing the logic a wrapped call hides from
  `Metrics/MethodLength`.
- `Elegant/OneClassPerFile` is enabled explicitly: on RuboCop releases before
  its own `Style/OneClassPerFile`, rubocop-elegant's config switched it off.
- `plan` no longer crashes under `LANG=C`, stages `Kata/PairedBrackets` and
  the Layout cops under a new `layout` stage, and a spec fails when a Kata cop
  is unstaged. `doctor` follows `inherit_from` (the todo file among it), names
  files it cannot read or parse instead of passing them, and lists every
  inline disable with its reason.
- The Gemfile tests released gems, and CI runs on both the newest releases and
  the oldest the gemspec allows (rubocop 1.75.1, rubocop-elegant 0.7.1). The
  floor moves from 1.75.0 to 1.75.1: 1.75.0's new `Style/ItBlockParameter`
  crashes on every `it` block.

Precision, measured on the same fifteen codebases: Kata offenses fall from
46,417 to 40,502, and what is left is what the rules are for.

- `Kata/NoBooleanFlag` looks where the flag is defined, not only where it is
  passed: a positional parameter that defaults to `true` or `false` is
  flagged, and a keyword one is the fix. Its new `AllowedMethods` holds the
  calls whose boolean is a protocol or a value rather than a flag —
  `respond_to?(name, true)`, `const_defined?(name, false)`,
  `fetch(:ssl, false)`, `instance_variable_set(:@done, false)` — and the defs
  whose signature Ruby dictates (`respond_to_missing?`). Call-site offenses
  in the corpus fall from 71 to 30; the 14 defaults it now finds are all real
  flags (`def self.ready(unset_env = false)`). Test files are exempt wherever
  they live.
- `Kata/GoodClassName` judges a test or a preview by its subject:
  `UsersControllerTest` is `UsersController`, and a `Suffixes` word (`Test`,
  `TestCase`, `Spec`, `Preview`) names what the class is for. `AllowedNames`
  gains the suffixes a framework resolves a class by: `Policy` (Pundit),
  `Component` (ViewComponent), `Generator`, `Channel`, `Mailbox`,
  `Subscriber`, `Adapter`, `Notifier`, and `Vendor`.
- `Kata/GoodClassName` and `Kata/GoodModuleName` read a doer as a verb plus
  `-er`/`-or`: a dictionary word whose stem is no verb (`Volunteer`,
  `Filter`, `Partner`, `Doctor`) is a thing, not a doer. An unknown coinage
  still counts.
- `Kata/GoodMethodName` leaves a Minitest `test_` method in a test class
  alone: it is a sentence, like the RSpec description it would be there. It
  also allows the names Rails, Pundit, Ransack, Devise and Phlex call by
  contract (`validate_each`, `table_name_prefix`, `policy_class`,
  `ransackable_attributes`, `cast_value`, `view_template`).
- `Kata/NoComments` excludes `config/` and `config.ru`, whose comments are
  the framework's generated guidance, and gains `AllowDocumentation` (off by
  default): a gem that publishes API docs keeps every comment block carrying
  a YARD tag, whole.
- `Kata/NoHashAsObject` allows a hash a constant names, frozen or not
  (`STATUS_ICONS = { … }`): a lookup table is a named object already.

Found by running the gem over fifteen MIT-licensed Rails apps and gems
(rubygems.org, Campfire, CodeTriage, CASA, Human Essentials, Homeward Tails,
railsdevs, Devise, Pundit, Kaminari, Faraday, Kamal, Solid Queue,
ViewComponent, GoodJob): their own suites, and `ruby -c`, after autocorrect.

- `Kata/NoRedundantVariable` autocorrect no longer writes Ruby that does not
  parse. It moved a heredoc's opener to the read and left the body behind
  (`execute(<<~SQL)` with no SQL); a heredoc assignment is now reported and
  left for a hand. It also inlined `{ … }.fetch(k)` as the first argument of
  a call without parentheses, where `{` opens a block; a value that starts
  with a brace is now wrapped there.
- `Kata/PairedBrackets` knows a lambda's brace. `-> {` was not an opener, so
  its `}` closed whichever bracket was open before it; offenses went missing
  and autocorrect edited the wrong token, which with
  `Layout/RedundantLineBreak` looped.
- `Kata/ConstructorDiscipline` reads `initialize` the way its message does:
  the guard and message of a `raise` are raising, and the body of a lambda or
  proc runs later, so neither is flagged. A safe-navigation call
  (`name&.strip`) was the one form it missed; it is flagged now.
- `Kata/NoClassMethodLogic` checks methods opened with `class << self`, which
  it skipped, and allows `from` and the hooks Ruby calls by name (`included`,
  `extended`, `inherited`, `prepended`).
- `Kata/NoHashAsObject` recognises keyword arguments on every call:
  `super(…)`, `yield(…)`, `obj&.call(…)`, and a call that also passes `&block`
  were read as hash literals.
- `Kata/GoodVariableName` and `Kata/RealWords` check `*rest`, `**options`, and
  `&block` parameters; a two-word name there slipped through.
- `Kata/RealWords` reads `v2` and `x10` as the single letters they are, and
  the supplement knows `admin`, `pdf`, `ssl`, `sms`, `i18n`, `ivar`,
  `sqlite`, `webauthn` and kin.
- `Kata/NoComments` keeps RDoc and YARD directives (`:nodoc:`, `:stopdoc:`,
  `:call-seq:`, `@!method`, `@!attribute`): a documentation tool reads them.
  YARD tags (`@param`, `@return`) are still prose.
- `Metrics/ParameterLists` is on. The bundled rubocop-elegant switches it off
  and the kata entry set `Max: 4` without `Enabled: true`, so the limit the
  README advertises never ran. A spec now fails if any cop kata tunes is left
  off by the plugins it bundles.
- The boot layer that `Kata/EnvDiscipline`, `Kata/IoDiscipline` and
  `Kata/ClockDiscipline` exempt now includes Gemfiles (`Gemfile`, `gems.rb`,
  `gemfiles/*.gemfile`), `config.ru`, `script/`, and migrations.
- Migrations are exempt from the cops whose shape Rails dictates there:
  `Kata/GoodClassName` and `Kata/ClassInModule` (the class name comes from the
  file name, at the top level), `Kata/NoClassMethodLogic` (`self.up`,
  `self.down`), and `Kata/NoBooleanFlag` (`change_column_null :t, :c, false`).
  `db/*schema.rb` is excluded outright: Rails regenerates it.
- `Elegant/NoEmptyLinesInBlocks` and `Elegant/NoEmptyLinesInMethods` stand
  down on every `*_spec.rb` and `*_test.rb`, not only under `spec/` and
  `test/`. RSpec's blank-line cops reach `examples/client_spec.rb` and
  `kaminari-core/test/`, and the two autocorrected in a loop.
- `RSpec/Output` no longer autocorrects: it deletes `print x` from
  `print x if cond` and leaves ` if cond`, which does not parse.
- `rubocop-kata plan` puts `Kata/ClassInModule` (it mints a module name) and
  `Kata/NoRedundantVariable` (it deletes names) under `structure`; both fell
  through to `rest`, after the naming work they change.

## [0.10.1] - 2026-09-26

- `Kata/ClassInModule` names the class in its message again: it read
  `Class {name: "Foo"} must be…` because the name went in as a keyword.
- `rubocop-kata plan` keeps its "these mint the names `naming` then prices"
  note for the `structure` stage; it was also printed when `naming` or `prose`
  came next, where it does not hold.
- Mutation testing with Kimera (`.kimera.yml`, `bundle exec kimera run`) now
  kills every mutant in `lib/`; the specs that got there pin the argument and
  class-variable hooks, the boundaries, and the correctors' edge cases. Dead
  guards it surfaced in `NoRedundantVariable`'s helpers and `doctor` are gone.
  CI keeps it there with `kimera ci`: pull requests gate on the lines they
  change, pushes to `main` on the full run.

## [0.10.0] - 2026-08-30

- `Elegant/NoRedundantVariable`, `Elegant/PairedBrackets`, and
  `Elegant/ClassInModule` now ship here, fixed, as `Kata/*` cops derived from
  rubocop-elegant under MIT (`LICENSE.txt`); the originals are
  off. The git-source Gemfile line is no longer needed: the correctors run
  out of the box, and `ClassInModule` clears.

## [0.9.0] - 2026-08-27

- The shared rule behind the naming cops is now explicit: compound syntax is
  not the smell — multiple semantic concepts are. A name should name one thing,
  not describe where it came from, what it manipulates, or which layer it
  lives in.
- New `Kata/GoodClassName` replaces `Kata/AgentNoun` and the class half of
  `Kata/NoUtilName`: a class names one object that exists in the model. It
  keeps the doer check and its derived suggestions, adds junk-drawer names
  matched whole or as a trailing segment (`Service` catches `InvoiceService`),
  and flags names packing more than `MaxWords` concepts
  (`CustomerOrderPayment`) unless `Terms` blesses them as one concept
  (`CreditCard`). The default `Terms` ships the established technical
  compounds: `AbstractSyntaxTree`, `RedBlackTree`, `UnitOfWork`,
  `TimeWithZone`, `HashWithIndifferentAccess` and kin.
- New `Kata/GoodModuleName` replaces the module half of `Kata/NoUtilName`: a
  module names a domain vocabulary, not an implementation category. Layer
  buckets (`Services`, `Helpers`, `Logic` — so `BusinessLogic` too), vague
  shared namespaces (`Common`, `Shared`, `Core`), doer modules, and crowded
  names are flagged; `AccessControl` and `Billing` pass.
- `Kata/GoodMethodName` flags names chaining actions with a conjunction
  (`validate_and_save`, `find_or_create`): each action wants its own method.
  Traversal names (`customer_address`) were already priced by the word rule;
  the message stays advisory — the cop cannot know your object model.
- `Kata/GoodMethodName` and `Kata/GoodVariableName` bless grammatical
  suffixes `id` and `ms` (`user_id`, `timeout_ms`) alongside `at`, the role
  prefixes `max`/`min`/`start`/`end` (`max_retries`, `start_time`), and ship
  established lexical compounds and protocol vocabulary as default `Terms`:
  `first_name`, `postal_code`, `time_zone`, `ip_address`, `user_agent`,
  `mime_type`, `status_code`, `access_token` and kin — names that read as one
  concept. Where names must mirror an external schema, `Exclude` the file:
  the file is the boundary.
- The defaults were then pressure-tested against corpora of real stdlib, gem,
  Rails, and business-domain names, and grew to absorb what any codebase hits:
  role suffixes (`number`, `code`, `price`, `rate`, `date`, `path`, `url`,
  `count`, `size`, `key`, `token`, `params`, `secret`, `level`, `file`, `dir`,
  `period`, `seconds`, `cents`), role prefixes (`current`, `default`, `total`,
  `new`, `other`, `raw`, `set`, `sort`, `expected`, `actual`, `assert`),
  domain terms (`line_item`, `credit_card`, `payment_method`,
  `billing_address`, `date_of_birth`, `dry_run`, `stack_trace` and kin), and
  the contract names of Ruby, Rails, Sidekiq, Devise, Pundit and RSpec
  (`perform_async`, `deconstruct_keys`, `authenticate_user!`, `policy_scope`,
  `failure_message` and kin). Name suffixes that would bless owner+property
  (`name`, `message`, `amount`) stayed out on purpose: `user_name` and
  `error_message` are still priced.
- `Kata/GoodClassName` `AllowedNames` also covers the class families a
  framework resolves or subclasses by name (`Validator`, `Decorator`,
  `Presenter`, `Helper`, `Job`, `Logger`, `Delegator`, `Enumerator`,
  `Driver`) and more thing-words (`Center`, `Transfer`);
  `Kata/GoodModuleName` mirrors the class cop's allowed list, and its
  `BannedNames` grows the layer plurals (`Jobs`, `Workers`, `Queries`,
  `Policies`, `Forms`, `Decorators`, `Presenters`, `Serializers`,
  `Validators`, `Mixins`, `Extensions`).
- The doer check no longer flags thing-words that merely end in `-er`/`-or`:
  `User`, `Order`, `Customer`, `Monitor`, `Buffer` and kin ship in
  `Kata/GoodClassName` `AllowedNames`. `Kata/GoodModuleName` ships the
  framework suffixes (`Controller`, `Mailer`, `Serializer`) so reopening
  `ActionController` is not an offense. `Kata/GoodMethodName` exempts the
  names Ruby and Rails resolve by contract: `method_missing`,
  `respond_to_missing?`, `marshal_dump`, `deep_dup`, `table_name`,
  `primary_key` and kin.

## [0.8.0] - 2026-08-20

- New `rubocop-kata plan` command: buckets the backlog into `structure`,
  `naming`, `prose` and `rest`, and names the stage to take next. Kata's
  structural cops create names and its naming cops charge for them, so the net
  offense count moves the wrong way mid-refactor and cannot be read as progress.
- New `rubocop-kata skill` command: prints an agent skill to stdout, so
  redirecting it installs the skill wherever an agent reads them from. It works
  the stage `plan` names one file at a time, checks every name it introduces
  against the dictionary `Kata/RealWords` reads, and reports removed and
  created separately.
- `Kata/AgentNoun` no longer truncates a compound to its prefix. Truncation is
  not injective — `EvidencePoller`, `EvidenceValidator` and `EvidenceWaiter`
  were each told to become `Evidence` — and it lands on names that already
  exist elsewhere, which a per-file cop cannot see. It now derives the agent
  word and keeps the rest, so `EvidenceValidator` suggests
  `EvidenceValidation`, and stays quiet when no derivation applies.
- `Kata/AgentNoun` `AllowedNames` gains `Controller`, `Mailer` and
  `Serializer`: suffixes a framework resolves a class by are contracts, not
  naming choices.
- `Kata/EnvDiscipline` no longer flags `ENV` as a parameter default.
  `def enabled?(env = ENV)` is the injection the cop asks for: the parameter
  is the seam, and the default is what the boot layer would pass anyway.
- Every cop that excluded `spec/**/*` now excludes `test/**/*` too. Fifteen
  cops shipped an RSpec-only exclusion, so a Minitest suite got the
  production rules.
- The boot layer that `Kata/EnvDiscipline`, `Kata/IoDiscipline` and
  `Kata/ClockDiscipline` exempt now covers an application's, not only a gem's:
  `config/`, `db/seeds.rb`, `db/seeds/`, `lib/tasks/`, `Rakefile` and
  `*.rake`, alongside `bin/` and `exe/`.
- `Kata/NoComments` now exempts `Gemfile` as it already exempts `*.gemspec`. A
  dependency manifest cannot say why a dependency is pinned in code.
- `Metrics/MethodLength` counts an array, hash, heredoc or method call that
  spans lines as one line. `Max: 5` and `Layout/LineLength: 120` were
  otherwise unsatisfiable together: wrapping a long line spent method budget.
- `Layout/ArgumentAlignment` now uses `with_fixed_indentation`. Its default
  aligns continuation arguments under the first argument's column, a step
  `Elegant/MonotonicIndents` rejects.
- `Layout/EmptyLinesAroundAttributeAccessor` is off. It requires a blank line
  after `attr_reader` where `Elegant/NoEmptyLinesInBlocks` forbids one; inside
  an `included do` block the two autocorrect in a loop.
- `Lint/NumberConversion` is off. Its message names a replacement that
  raises: `Integer(x, 10)` is only valid when `x` is a String, and a `.to_i`
  receiver is usually a Time, a BigDecimal or an Integer.
- The five bundled cops that exempt test files now also match Rails'
  `foo_test.rb`, `foo_spec.rb`, and suites addressed by directory. Upstream
  matched `**/*Test.rb` and `**/test_*.rb` only.
- `Elegant/ClassInModule` is off. Its offenses cannot be cleared: it reports a
  class nested in a class as global, and `Elegant/NoClassInModule` forbids the
  module its message asks for, so the pair admits no shape. It also reads a
  top-level constant as a defect, which is how Rails resolves one. Reported
  upstream as yegor256/rubocop-elegant#75.
- `Elegant/PairedBrackets` autocorrect is off. It inserts a newline beside a
  bracket without taking the whitespace already there, so corrected lines drift
  right and `Elegant/MonotonicIndents` then reports the line it just wrote. The
  rule still reports; fix the brackets by hand. Reported upstream as
  yegor256/rubocop-elegant#76.
- Development runs against giacope/rubocop-elegant#fixes, the released gem plus
  five open pull requests. A gemspec cannot name a git source, so consumers who
  want the fixes rather than the workarounds add the same line to their own
  Gemfile; the README says how.

## [0.7.0] - 2026-08-16

- New `rubocop-kata doctor` command: reports `.rubocop.yml` entries that
  configure a cop the inherited configuration already disables, and
  `rubocop:disable`/`enable` comments naming a cop that is not enabled where
  the comment sits. RuboCop reports neither. Exits non-zero when it finds
  something.
- `Style/DisableCopsWithinSourceCodeDirective` is now on.
- `Kata/AgentNoun` suggests a name when it can derive one: a compound minus its
  agent word (`PaymentProcessor` -> `Payment`), or a regular
  -ator/-ector/-isor/-izer noun the shipped dictionary confirms (`Selector` ->
  `Selection`, `Synthesizer` -> `Synthesis`). It never proposes a name it would
  flag in turn.
- `Kata/AgentNoun` `AllowedNames` entries now match a whole name or a trailing
  segment of one, so the default `Error` also exempts `UsageError` and
  `ParseError` without listing them.
- `Kata/BuilderNoun` gained `AllowedNames`, for the method whose name an
  external API dictates (`get_callbacks`).
- The dictionary moved to `RuboCop::Kata::Dictionary`, shared by
  `Kata/RealWords` and `Kata/AgentNoun`.

## [0.6.0] - 2026-08-15

- The base dictionary is now SCOWL en-US size 60 (~83k words including
  inflections — https://wordlist.aspell.net, see data/SCOWL-COPYRIGHT), so the
  hand-rolled stemmer shrank to productive derivations only (-able, -er/-or
  agent nouns, -less, plurals for supplement/software terms).
- `Kata/RealWords` now also draws on a vendored dictionary of software
  vocabulary (`data/software.txt.gz`, ~4300 words) built from the MIT-licensed
  cspell `software-terms`, `ruby`, and `shell` dictionaries
  (https://github.com/streetsidesoftware/cspell-dicts) — `argv`, `stderr`,
  `klass`, `mutex`, `regex`, and friends no longer need per-project `Terms`.
- The stemmer understands comparatives (`newer`, `deeper`), superlatives
  (`longest`), and `-ied` pasts (`denied`); common irregular pasts (`held`,
  `paid`, `heard`) joined the supplement.
- `Kata/GoodMethodName` ignores operator methods (`[]`, `==`, `<=>`, `<<`) —
  Ruby dictates their names.
- `Kata/GoodVariableName` ships `_include_private` (the `respond_to_missing?`
  protocol argument) in its default `AllowedNames`.

## [0.5.0] - 2026-08-15

- New cops `Kata/GoodMethodName` and `Kata/GoodVariableName`. One word is the
  default and the goal; a second word is allowed only when it is not hiding a
  missing object — a role prefix (`after_fork`, `each_group`, `to_h`), a role
  suffix (`file_of`, `tests_for`, `points_at`), or a compound noun listed in
  `Terms:`. `Terms:` is a budget you spend consciously, like `max_ignored` in a
  mutation-testing config, not a silent escape hatch. `verb_receiver` names
  (`build_adapter`, `apply_excludes`, `covering_count`) stay offenses, and so do
  three-word names. The variable cop understands `@`, `@@`, `$`, and the
  `_unused`/`@_memo` conventions.
- New cop `Kata/RealWords` replaces `Kata/NoAbbreviation`. A blocklist has to
  enumerate its whole domain to work: an abbreviation nobody thought to ban
  passed silently, and deleting the underscore (`matching_ids` → `matchingids`)
  dodged the naming cops entirely. The check is now inverted — every
  underscore-separated segment of a name must be a word the gem's shipped
  dictionary knows, so `errorcount` and `cfg` fail with zero configuration
  while `deadline` and `mutant` sail through. The dictionary is the web2
  wordlist (lowercase, 2–16 letters, gzipped in `data/`), a visible
  `data/supplement.txt` of modern vocabulary web2 predates (`json`,
  `memoize`, `timestamp`), and a light stemmer for plurals, `-ed`, `-ing`,
  `-able`, and `un-`/`re-`/`non-`. `BannedWords:` keeps flagging abbreviations
  that happen to be dictionary words (`err`, `res`, `pos`); `Terms:` is the
  reviewed domain-jargon budget and overrides `BannedWords:`; `AllowedNames:`
  exempts names an external protocol dictates (`def pos` on a scanner,
  `def env` for Rack). Operator names, single-letter segments, and the
  `_unused`/`@_memo` shapes are ignored. Method names, ivars, class variables,
  and globals are all checked — `Kata/NoAbbreviation` saw only locals and
  parameters.
- `Elegant/GoodMethodName` and `Elegant/GoodVariableName` are now disabled:
  Kata owns naming, and the upstream one-word-only rule is what pushed people
  into deleting underscores in the first place.
- Removed `Kata/NoNilReturn`: duplicate of the bundled `Elegant/NoNilReturn`,
  which covers a superset (blocks, lambdas, `kwbegin` tails).

## [0.4.0] - 2026-08-14
- `Naming/MemoizedInstanceVariableName` enforced with
  `EnforcedStyleForLeadingUnderscores: required`: memoization caches are
  named `@_name`, marking lazy state at the read site.
- `Elegant/GoodVariableName` pattern extended to accept the `@_word`
  memo shape.

## [0.3.0] - 2026-08-14

- Ten new house cops in the Elegant Objects spirit, all on by default:
  `Kata/NoUtilName`, `Kata/NoAbbreviation`, `Kata/BuilderNoun`, `Kata/NoBooleanFlag`,
  `Kata/ConstructorDiscipline`, `Kata/NoClassMethodLogic`, `Kata/NoHashAsObject`,
  `Kata/NoNilReturn`, `Kata/ClockDiscipline`, `Kata/EnvDiscipline`.

## [0.2.1] - 2026-08-13

- `Style/MethodCallWithArgsParentheses` disabled, overriding rubocop-elegant.
- Disabled nine core `Layout/*` cops that autocorrect-loop against `Elegant/PairedBrackets` and `Elegant/NoEmptyLines*`.
- `AutoCorrect: false` on `Elegant/NoRedundantVariable`, `Style/StaticClass`, and `Lint/NumberConversion` — their correctors rewrite code incorrectly.
- `Style/RequireOrder` disabled — alphabetizing requires breaks load-order-dependent boot.

## [0.2.0] - 2026-08-10

- Kata cops now run globally instead of only in `lib/**` — code in `app/`, `Rakefile`, etc. is now covered.
- `Kata/NoComments` excludes specs and gemspecs by default.
- `Kata/IoDiscipline` excludes specs, `bin/`, `exe/`, `Rakefile`, and gemspecs by default — bare `puts` in scripts and entrypoints stays legal.

## [0.1.2] - 2026-08-10

- `Kata/IoDiscipline` is on by default for `lib/**` — library code never prints without a receiver.

## [0.1.1] - 2026-08-10

- `Elegant/NoEmptyLinesInMethods` excludes specs by default, matching `Elegant/NoEmptyLinesInBlocks`.

## [0.1.0] - 2026-08-10

- Initial release.
- Cops: `Kata/AgentNoun`, `Kata/NoComments` (autocorrecting), `Kata/IoDiscipline`, `Kata/ProsePlacement`.
- Shared defaults bundling rubocop-rspec, rubocop-performance, rubocop-elegant, rubocop-packaging, and rubocop-thread_safety.
