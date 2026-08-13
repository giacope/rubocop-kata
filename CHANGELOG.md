# Changelog

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
