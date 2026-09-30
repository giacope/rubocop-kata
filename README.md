# rubocop-kata

A RuboCop plugin that replaces a pile of linter gems and config with one dependency. Install it and your `.rubocop.yml` shrinks to project-specific overrides. Everything else comes from the gem: a curated stack of RuboCop extensions, opinionated style defaults, and eighteen house cops.

`Kata/GoodMethodName` asks for one word per method name. A second word is
allowed only when it is not hiding a missing object: a role prefix
(`after_fork`), a role suffix (`file_of`), or a compound noun you have added to
`Terms` on purpose. The wrong way to satisfy the cop is `matching_ids` →
`matchingids`: if you need two words, that is a modelling smell — the concept is
missing, or the method belongs on a different object. `Kata/RealWords` catches
that dodge with a shipped dictionary instead of a word list you maintain:
`matchingids` is not a word, so it fails with zero configuration — and so does
`cfg`.

- **One dependency.** Bundles rubocop-rspec, rubocop-performance, rubocop-elegant, rubocop-packaging, and rubocop-thread_safety behind a single gem.
- **Opinionated defaults.** Methods under 5 lines, classes under 100, 4 parameters max, 120-column lines, double quotes, `NewCops: enable`. See [config/default.yml](config/default.yml).
- **Eighteen house cops.** Naming, dependency discipline, and data honesty in the Elegant Objects spirit — from `Kata/GoodClassName` to `Kata/ClockDiscipline`.

```ruby
class PaymentProcessor  # Kata/GoodClassName: `PaymentProcessor` names a doer; name the class
end                     #   for the thing it is, not the work it does. Try `Payment`.

class Payment           # OK
end
```

It suggests a name only when it can derive one: a compound minus its agent word,
or a regular `-ator`/`-ector`/`-isor`/`-izer` noun the shipped dictionary
confirms (`Selector` → `Selection`, `Synthesizer` → `Synthesis`).

## Getting started

Add the gem to your `Gemfile`:

```ruby
gem "rubocop-kata", group: :development, require: false
```

Install it and point `.rubocop.yml` at the plugin:

```yaml
plugins:
  - rubocop-kata

AllCops:
  TargetRubyVersion: 3.4
```

```sh
bundle install
bundle exec rubocop
```

That's it. The plugin loads the bundled extensions and the shared defaults, so your `.rubocop.yml` keeps only what's specific to your project. Requires Ruby >= 3.4 and RuboCop ~> 1.75.

### The bundled rubocop-elegant

The released `rubocop-elegant` 0.7.1 has four defects this project reported
upstream: `NoRedundantVariable` autocorrect corrupts Ruby 3.1 shorthand
([#74](https://github.com/yegor256/rubocop-elegant/issues/74)), `ClassInModule`
reports a class nested in a class as global
([#75](https://github.com/yegor256/rubocop-elegant/issues/75)),
`PairedBrackets` autocorrect drifts the indent
([#76](https://github.com/yegor256/rubocop-elegant/issues/76)), and the
test-file exclusions never match a Rails or RSpec suite
([#77](https://github.com/yegor256/rubocop-elegant/issues/77)).

Until upstream releases the fixes, the three cops ship here, fixed, as
`Kata/NoRedundantVariable`, `Kata/PairedBrackets`, and `Kata/ClassInModule`;
the `Elegant/*` originals are off so each offence is reported once. They are
derived from rubocop-elegant under its MIT licence, and the notice travels
with the gem as `LICENSE.txt`. The exclusions are widened.
Once upstream ships, the copies go and the originals come back on.

On a Rails codebase, consider turning `Kata/ClassInModule` off: it wants
every class inside a module, and Zeitwerk resolves `class Account` from
`app/models/account.rb` as a top-level constant by design.

## The cops

| Cop | Default | What it enforces |
| --- | --- | --- |
| `Kata/GoodClassName` | on | A class names one object that exists in the model: no `-er`/`-or` doers (suggests the better name when it can derive one), no junk drawers (`Service`, `Util`, `Data`), no packing several concepts into one name (`CustomerOrderPayment`). Compound syntax is not the smell — `CreditCard` is one concept, and `Terms` holds those. `AllowedNames` and `BannedNames` match a whole name or a trailing segment, so `Error` covers `UsageError` and `Service` catches `InvoiceService`. |
| `Kata/GoodModuleName` | on | A module names a domain vocabulary (`Billing`, `AccessControl`), not an implementation category: no layer buckets (`Services`, `Helpers`, `Logic`), no vague shared namespaces (`Common`, `Shared`, `Core`), no doers. Tune via `BannedNames`/`Terms`/`AllowedNames`. |
| `Kata/NoRedundantVariable` | on | A local assigned once and read once is inlined at its read, unless the move would cross a loop, a branch, or a side effect. Autocorrects, and keeps Ruby 3.1 shorthand intact. Fixed copy of `Elegant/NoRedundantVariable`. |
| `Kata/PairedBrackets` | on | Every bracket pairs on its line, or opens at line end and closes at line start. Autocorrects without drifting the indent. Fixed copy of `Elegant/PairedBrackets`. |
| `Kata/ClassInModule` | on | A class lives in a module, a class, or a compact namespace, never at the top level. Fixed copy of `Elegant/ClassInModule`. |
| `Kata/NoComments` | on | No prose comments; say it in the code. Magic comments, linter directives, RDoc and YARD directives (`:nodoc:`, `@!method`), and licence headers survive. Autocorrects. |
| `Kata/IoDiscipline` | on | No bare `puts`/`warn`/`pp`/`p` outside the test suite and the boot layer; write through an injected `@io` or an explicit receiver. |
| `Kata/ProsePlacement` | off | Sentence-length strings belong in the presentation layer. Enable with an `Include`/`Exclude` matching your layering. |
| `Kata/RealWords` | on | Every name segment is a word the shipped dictionary knows — `errorcount` (smash) and `cfg` (abbreviation) both fail, with no word list to maintain. Tune via `Terms`/`BannedWords`/`AllowedNames`. |
| `Kata/GoodMethodName` | on | One word per method name; a second word needs a role prefix (`after_fork`), a role suffix (`file_of`), or a reviewed `Terms` entry. A name chaining actions (`validate_and_save`, `find_or_create`) is flagged as two methods in one. Tune via `MaxWords`/`Prefixes`/`Suffixes`/`Terms`/`AllowedNames`. |
| `Kata/GoodVariableName` | on | The same rule for locals, parameters, ivars, class variables, and globals; `_name` and `@_name` stay exempt. |
| `Kata/BuilderNoun` | on | Builders named for what they return: `total`, not `calculate_total`. Tune via `BannedPrefixes`/`AllowedNames`. |
| `Kata/NoBooleanFlag` | on | No positional boolean arguments; split the method or use a keyword. |
| `Kata/ConstructorDiscipline` | on | `initialize` assigns, raises, or freezes — never computes. |
| `Kata/NoClassMethodLogic` | on | Class methods construct (`build`, `parse`, `of`, `from`, `from_*`) or answer a Ruby hook (`included`, `inherited`); instances do the work. Methods opened with `class << self` count. |
| `Kata/NoHashAsObject` | on | A hash with `MaxKeys`+ keys (default 4) wants to be an object. Keyword-argument call sites exempt. |
| `Kata/ClockDiscipline` | on | No bare `Time.now`/`Date.today`/`.current`; inject a clock. |
| `Kata/EnvDiscipline` | on | `ENV` reads only in the boot layer (`config/`, `config.ru`, `db/seeds*`, `db/migrate/`, `lib/tasks/`, rake files, Gemfiles, `bin/`, `exe/`, `script/`) — or as a parameter default, which is the seam the cop asks for. |

## Dead configuration

`doctor` reports configuration that no longer does anything: a `.rubocop.yml`
entry for a cop the inherited configuration disables, and a
`rubocop:disable`/`enable` comment naming a cop that is not enabled where the
comment sits. RuboCop reports neither.

```sh
bundle exec rubocop-kata doctor          # or: doctor path/to/project
```

```
.rubocop.yml:20: `Elegant/GoodMethodName` is disabled by the configuration this project inherits; the entry does nothing.
lib/registry.rb:44: the directive names `Elegant/GoodMethodName`, which is not enabled here; the comment does nothing.
2 dead entries
```

It exits non-zero when it finds something, so it can gate CI.

## Adoption order

Kata's structural cops create names and its naming cops charge for them, so a
structural refactor removes offenses and adds more. A single total cannot tell
progress from regression. `plan` buckets the backlog into the stages that cause
each other and names the one to take next.

```sh
bundle exec rubocop-kata plan            # or: plan path/to/project
```

```
structure     184  Kata/ConstructorDiscipline 92, Kata/NoHashAsObject 48, Kata/EnvDiscipline 44
naming        263  Kata/RealWords 141, Kata/GoodVariableName 88, Kata/GoodClassName 34
prose          57  Kata/NoComments 57
rest          412  Elegant/PairedBrackets 300, Layout/LineLength 112
next: structure — 184 offenses in 61 files; these mint the names `naming` then prices, so take them first
densest: app/models/account.rb (14)
```

Structure before naming, because doing naming first means renaming things the
structural pass is about to move.

The gem also ships an agent skill that runs this loop: it works the stage `plan`
names, checks every name it introduces against the same dictionary
`Kata/RealWords` reads, and reports removed and created separately instead of a
net total.

```sh
mkdir -p .claude/skills/rubocop-kata
bundle exec rubocop-kata skill > .claude/skills/rubocop-kata/SKILL.md
```

It writes to stdout, so the same command installs it anywhere an agent reads
skills from — a project, `~/.claude/skills/`, or a plugin.

## The defaults

Double-quoted strings, `Metrics/MethodLength: 5`, `Metrics/ClassLength: 100`,
`Metrics/ParameterLists: 4`, 120-column lines, endless methods on one line,
`rescue => error`, `NewCops: enable`, heredocs counted as one line in spec
examples, and no inline `rubocop:disable` comments
(`Style/DisableCopsWithinSourceCodeDirective`). See
[config/default.yml](config/default.yml).

## License

The code is MIT — see [LICENSE.txt](LICENSE.txt). The shipped dictionaries are
third-party data under their own terms:

- **`data/words.txt.gz`** — a *modified* subset of [SCOWL](https://wordlist.aspell.net)
  en-US size 60: filtered, deduplicated, and gzipped. SCOWL is the collective work of
  Kevin Atkinson and the contributors named in
  [data/SCOWL-COPYRIGHT](data/SCOWL-COPYRIGHT), which is distributed with this gem and
  reproduced verbatim. It includes, among others, Copyright 2000–2018 Kevin Atkinson;
  WordNet 1.6 Copyright 1997 by Princeton University, all rights reserved; and Copyright
  1993 Geoff Kuenning, Granada Hills, CA, all rights reserved. Princeton University makes
  no representations or warranties, express or implied, as to this database, and its name
  may not be used in advertising or publicity pertaining to this distribution.
- **`data/software.txt.gz`** — built from the `software-terms`, `ruby`, and `shell`
  dictionaries of [cspell-dicts](https://github.com/streetsidesoftware/cspell-dicts),
  each MIT-licensed. Copyright (c) 2017–2025 Street Side Software; the notice and
  permission text are reproduced in [data/CSPELL-LICENSE](data/CSPELL-LICENSE).
- **`data/supplement.txt`** — this project's own additions, MIT.
