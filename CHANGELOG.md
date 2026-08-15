# Changelog

## [Unreleased]

## [0.6.0] - 2026-08-15

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
