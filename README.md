# rubocop-kata

A RuboCop plugin that replaces a pile of linter gems and config with one dependency. Install it and your `.rubocop.yml` shrinks to project-specific overrides. Everything else comes from the gem: a curated stack of RuboCop extensions, opinionated style defaults, and fifteen house cops.

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
- **Fifteen house cops.** Naming, dependency discipline, and data honesty in the Elegant Objects spirit — from `Kata/AgentNoun` to `Kata/ClockDiscipline`.

```ruby
class PaymentProcessor  # Kata/AgentNoun: `PaymentProcessor` names a doer;
end                     #   name the class for the thing it is, not the work it does.

class Payment           # OK
end
```

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

## The cops

| Cop | Default | What it enforces |
| --- | --- | --- |
| `Kata/AgentNoun` | on | Classes named for what they are, not `-er`/`-or` doers. Allow exceptions via `AllowedNames`. |
| `Kata/NoComments` | on | No prose comments; say it in the code. Magic comments, linter directives, and licence headers survive. Autocorrects. |
| `Kata/IoDiscipline` | on | No bare `puts`/`warn`/`pp`/`p` outside specs/scripts; write through an injected `@io` or an explicit receiver. |
| `Kata/ProsePlacement` | off | Sentence-length strings belong in the presentation layer. Enable with an `Include`/`Exclude` matching your layering. |
| `Kata/NoUtilName` | on | No junk-drawer names (`Util`, `Helper`, `Manager`, `Service`, …). Tune via `BannedNames`. |
| `Kata/RealWords` | on | Every name segment is a word the shipped dictionary knows — `errorcount` (smash) and `cfg` (abbreviation) both fail, with no word list to maintain. Tune via `Terms`/`BannedWords`/`AllowedNames`. |
| `Kata/GoodMethodName` | on | One word per method name; a second word needs a role prefix (`after_fork`), a role suffix (`file_of`), or a reviewed `Terms` entry. Tune via `MaxWords`/`Prefixes`/`Suffixes`/`Terms`/`AllowedNames`. |
| `Kata/GoodVariableName` | on | The same rule for locals, parameters, ivars, class variables, and globals; `_name` and `@_name` stay exempt. |
| `Kata/BuilderNoun` | on | Builders named for what they return: `total`, not `calculate_total`. Tune via `BannedPrefixes`. |
| `Kata/NoBooleanFlag` | on | No positional boolean arguments; split the method or use a keyword. |
| `Kata/ConstructorDiscipline` | on | `initialize` assigns, raises, or freezes — never computes. |
| `Kata/NoClassMethodLogic` | on | Class methods construct (`build`, `parse`, `of`, `from_*`); instances do the work. |
| `Kata/NoHashAsObject` | on | A hash with `MaxKeys`+ keys (default 4) wants to be an object. Keyword-argument call sites exempt. |
| `Kata/ClockDiscipline` | on | No bare `Time.now`/`Date.today`/`.current`; inject a clock. |
| `Kata/EnvDiscipline` | on | `ENV` reads only in the boot layer (`config/`, `bin/`, `exe/`). |

## The defaults

Double-quoted strings, `Metrics/MethodLength: 5`, `Metrics/ClassLength: 100`,
`Metrics/ParameterLists: 4`, 120-column lines, endless methods on one line,
`rescue => error`, `NewCops: enable`, and heredocs counted as one line in
spec examples. See
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
