# Changelog

## [Unreleased]

- `Elegant/ClassInModule` is off. Its offences cannot be cleared: it reports a
  class nested in a class as global, and `Elegant/NoClassInModule` forbids the
  module its message asks for, so the pair admits no shape. It also reads a
  top-level constant as a defect, which is how Rails resolves one. Reported
  upstream as yegor256/rubocop-elegant#75.
- `Elegant/PairedBrackets` autocorrect is off. It inserts a newline beside a
  bracket without taking the whitespace already there, so corrected lines drift
  right and `Elegant/MonotonicIndents` then reports the line it just wrote. The
  rule still reports; fix the brackets by hand. Reported upstream as
  yegor256/rubocop-elegant#76.
- `Kata/NoComments` now exempts `Gemfile` as it already exempts `*.gemspec`. A
  dependency manifest cannot say why a dependency is pinned in code.
- Development runs against giacope/rubocop-elegant#fixes, the released gem plus
  the five open pull requests. A gemspec cannot name a git source, so consumers
  who want the fixes rather than the workarounds add the same line to their own
  Gemfile; the README says how.

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
- `Layout/ArgumentAlignment` now uses `with_fixed_indentation`. Its default
  aligns continuation arguments under the first argument's column, a step
  `Elegant/MonotonicIndents` rejects.
- `Layout/EmptyLinesAroundAttributeAccessor` is off. It requires a blank line
  after `attr_reader` where `Elegant/NoEmptyLinesInBlocks` forbids one; inside
  an `included do` block the two autocorrect in a loop.
- The five bundled cops that exempt test files now also match Rails'
  `foo_test.rb`, `foo_spec.rb`, and suites addressed by directory. Upstream
  matched `**/*Test.rb` and `**/test_*.rb` only.
- `Lint/NumberConversion` is off. Its message names a replacement that
  raises — `Integer(x, 10)` is only valid when `x` is a String, and a `.to_i`
  receiver is usually a Time, a BigDecimal or an Integer.
- `Metrics/MethodLength` counts an array, hash, heredoc or method call that
  spans lines as one line. `Max: 5` and `Layout/LineLength: 120` were
  otherwise unsatisfiable together: wrapping a long line spent method budget.

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
