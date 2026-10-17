# rubocop-kata

A RuboCop plugin that replaces a pile of linter gems and config with one dependency. Install it and your `.rubocop.yml` shrinks to project-specific overrides. Everything else comes from the gem: a curated stack of RuboCop extensions, opinionated style defaults, and nineteen house cops.

Kata's naming and size rules began as Elegant Objects' one-word names and
five-line methods. We measured them and they moved. In a blind readability
study, two samples each held 30 entry methods (with their same-class helpers)
from kimera and hashira, two codebases written to kata's rules, and 30 from
rubocop, faraday and rubygems.org. Each sample was rated by two independent
AI reviewers (separate model instances that saw only the code, shuffled, with
no source names), who agreed on 54 and 55 of 60 calls; no human has rated it
yet. Readers judged 14–16 of the 30 house-style items
over-fragmented, against 0–2 of 30 in the control. They scored readability
about 3.0 against 4.0 and name clarity about 2.5 against 4.1, calling the
one-word names vague or metaphorical (`rolls`, `homes`, `sightings`,
`pinpoint`). House-style methods averaged 3.0 lines, the control 6.3. The
study cannot separate the rules from the people who followed them, but it
points one way, and the defaults followed:

- **Methods** may run to RuboCop's 10 lines. Logic density is what is
  bounded, by `Metrics/AbcSize` 17, `CyclomaticComplexity` 7 and
  `PerceivedComplexity` 8.
- **Names** may take two words (`parse_header`, `line_items`), not counting
  role words (`after_fork`, `file_of`). Three or more words still fail, and
  so do chained actions (`validate_and_save`). `Kata/RealWords` still fails a
  smash (`matchingids`) and a clipping (`cfg`). `MaxWords: 1` restores the
  one-word discipline for a team that wants it.

The study's items and ratings are in hashira, under
`eval/results/fragmentation/`.

- **One dependency.** Bundles rubocop-rspec, rubocop-performance, rubocop-elegant, rubocop-packaging, and rubocop-thread_safety behind a single gem.
- **Opinionated defaults.** Methods up to 10 lines and bounded by complexity, classes under 100, 4 parameters max, 120-column lines, double quotes, `NewCops: enable`. See [config/default.yml](config/default.yml).
- **Nineteen house cops.** Naming, dependency discipline, and data honesty in the Elegant Objects spirit — from `Kata/GoodClassName` to `Kata/ClockDiscipline`.

```ruby
class PaymentProcessor  # Kata/GoodClassName: `PaymentProcessor` names a doer; name the class
end                     #   for the thing it is, not the work it does.

class Payment           # OK
end
```

A doer is an agent noun, not a word that ends in `-er`: data derived from
WordNet says whether a word's dominant sense is "one that parses" (`Parser`,
`Timer`) or a thing (`Number`, `Layer`, `Order`, `Folder`). On 400 labelled
names its precision is 0.99 where the old "is the stem a word" test scored
0.75 (see [eval/results](eval/results/README.md)). It suggests a name only when
it can derive one (`Selector` → `Selection`).

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

That's it. The plugin loads the bundled extensions and the shared defaults, so your `.rubocop.yml` keeps only what's specific to your project. Requires Ruby >= 3.4 and RuboCop ~> 1.75 (1.75.1 or later).

### The bundled rubocop-elegant

Kata reported four rubocop-elegant defects upstream
([#74](https://github.com/yegor256/rubocop-elegant/issues/74)–[#77](https://github.com/yegor256/rubocop-elegant/issues/77));
0.8.0 fixes them, but Kata's copies carry further fixes found on real codebases
(a heredoc inlined without its body, a lambda's brace, the indent after a
nested break), so `Kata/NoRedundantVariable`, `Kata/PairedBrackets`, and
`Kata/ClassInModule` stay, and the `Elegant/*` originals stay off. They are
derived from rubocop-elegant under its MIT licence (see `LICENSE.txt`). CI tests
both the oldest releases the gemspec allows and the newest.

## The cops

| Cop | Default | What it enforces |
| --- | --- | --- |
| `Kata/GoodClassName` | on | A class names one object that exists in the model: no doers (agent nouns, read from WordNet data), no junk drawers (`Service`, `Util`, `Data`), no packing several concepts into one name (`CustomerOrderPayment`). `CreditCard` is one concept; `Terms` holds those. A framework's suffix is a contract, its subject is not: `UsersController` is judged as `Users`, `ReportBuilderJob` as `ReportBuilder`. A class inherits the agent word of the superclass that chose it (`ActionHandler < Avo::Actions::ActionHandler`). `AllowedNames` holds exception classes and the domain roles a model represents (`User`, `Owner`). |
| `Kata/GoodModuleName` | on | A module names a domain vocabulary (`Billing`, `AccessControl`), not an implementation category: no layer buckets (`Services`, `Helpers`, `Logic`), no vague shared namespaces (`Common`, `Shared`, `Core`), no doers. Rails helper modules (`InvoicesHelper`) are judged by their subject. |
| `Kata/NoRedundantVariable` | on | A local assigned once and read once is inlined at its read, unless the move would cross a loop, a branch, or a side effect. Autocorrects, and keeps Ruby 3.1 shorthand intact. Fixed copy of `Elegant/NoRedundantVariable`. |
| `Kata/PairedBrackets` | on | Every bracket pairs on its line, or opens at line end and closes at line start. Autocorrects without drifting the indent. Fixed copy of `Elegant/PairedBrackets`. |
| `Kata/ClassInModule` | on | A class lives in a module, a class, or a compact namespace, never at the top level. A file directly in a Zeitwerk root (`app/models/account.rb`) is exempt: Rails resolves it as a top-level constant by design. Fixed copy of `Elegant/ClassInModule`; `Elegant/NoClassInModule`, which allowed only the compact form, is off. |
| `Kata/NoComments` | on | No prose comments; say it in the code. Code cannot cite an external constraint, so a block citing a URL, an issue (`rails/rails#123`), an RFC or a CVE is kept, as are YARD-documented blocks (`AllowDocumentation`), magic comments and editor modelines, tool directives (RuboCop, Standard, Steep, RBS, reek, kimera, hashira…; `AllowedPatterns` for more), and licence headers. Deleting a comment loses what it said, so it corrects only under `rubocop -A`. |
| `Kata/IoDiscipline` | on | No bare `puts`/`warn`/`pp`/`p` outside the test suite and the boot layer; write through an injected `@io` or an explicit receiver. |
| `Kata/ProsePlacement` | off | Sentence-length strings belong in the presentation layer. Enable with an `Include`/`Exclude` matching your layering. |
| `Kata/RealWords` | on | Every name segment is a word: English, an initialism, a technology's name, or the platform's own spelling (`env`, `params`, `attr`, `io`). `errorcount` (a smash) fails, and so does every clipping, whichever dictionary lists it: `args`, `opts`, `src`, `impl`, `str`, `req`, `conn`, with the word named in the message. `foo` is a placeholder. Tune via `Terms`/`BannedWords`/`AllowedNames`. |
| `Kata/GoodMethodName` | on | At most two words per method name (`MaxWords`), not counting a role prefix (`after_fork`), a role suffix (`file_of`) or a reviewed `Terms` entry; three or more words describe a missing object. A name chaining actions (`validate_and_save`) is two methods in one. Names minted by `attr_*`, `define_method`, `alias_method` and `alias` count. A Minitest `test_` method in a test class goes unpriced. |
| `Kata/GoodVariableName` | on | The same rule for locals, parameters, ivars, class variables, and globals; `_name` and `@_name` stay exempt. |
| `Kata/BuilderNoun` | on | Builders named for what they return: `total`, not `calculate_total`. Tune via `BannedPrefixes`/`AllowedNames`. |
| `Kata/NoBooleanFlag` | on | No positional boolean arguments, and no positional parameter defaulting to one; split the method or use a keyword. `AllowedMethods` holds the calls whose boolean is a protocol or a value (`respond_to?(name, true)`, `fetch(:ssl, false)`). |
| `Kata/ConstructorDiscipline` | on | `initialize` assigns, raises, or freezes — never computes. Shaping an argument (`Array(x)`, `name.to_s`, `items.dup`) and the object's own lock or empty collection (`Mutex.new`, `Set.new`) are assignment; a clock, a random number or a client is a hidden dependency. |
| `Kata/NoClassMethodLogic` | on | Class methods construct (`build`, `parse`, `of`, `from_*`, `new`, `[]`), answer a Ruby hook (`included`, `inherited`), or a serialization protocol (`load`/`dump`, `json_create`); instances do the work. |
| `Kata/NoHashAsObject` | on | A hash with `MaxKeys`+ keys (default 4) wants to be an object. Keyword arguments, a lookup table a constant names, and the hash `to_h`/`as_json` return are exempt. |
| `Kata/ClockDiscipline` | on | No ambient clock (`Time.now`, `Time.zone.now`, `Date.current`, `Time.new`, `Process.clock_gettime`); inject one. A parameter default is the seam: `def stamp(now: Time.now)`. |
| `Kata/JustifiedDirective` | on | An inline `rubocop:disable` says why after `--` (`# rubocop:disable Kata/GoodClassName -- Avo resolves the handler by this name`), so a false positive costs one reviewed line, not a per-file `Exclude`. |
| `Kata/EnvDiscipline` | on | `ENV` reads only in the boot layer (`config/`, `config.ru`, `db/seeds*`, `db/migrate/`, `lib/tasks/`, rake files, Gemfiles, `bin/`, `exe/`, `script/`) — or as a parameter default, which is the seam the cop asks for. |
| `Kata/NoSetter` | on | No `attr_writer`, `attr_accessor` or `def name=`: an object takes its state in the constructor, and a change returns a new object. `[]=` is a collection's protocol and passes. |
| `Kata/FrozenState` | on | An instance variable is assigned in `initialize` (or `initialize_copy`, or a helper only those call) and nowhere else. Memoization passes: `@x ||= ...`, `@x = ... unless @x`, `if @x.nil?`, `@x = @x \|\| ...`, `return @x if defined?(@x)`. Rails controllers, mailers and helpers, which hand views their data through ivars, are excluded. |
| `Kata/NoOutputArgument` | on | A method does not change what it was handed: `list << x`, `options.delete(:k)`, `hash[k] = v` and the other `MutatingMethods` on a parameter. Splats (`*args`, `**options`) are fresh collections, a parameter reassigned first (`list = list.dup`) is a copy, and `AllowedNames` holds the sinks (`io`, `out`, `buffer`, Rack's `env`). |
| `Kata/CommandQuery` | on | A `?` method answers and changes nothing: no ivar assignment (memoizing the answer passes) and no `!` call on itself, its state or its parameters. A bang whose value the query reads (`policy!(user, record).show?`) is a lookup that raises, and passes. |

## Dead configuration

`doctor` reports configuration that no longer does anything: an entry in
`.rubocop.yml` or any file it inherits (`.rubocop_todo.yml` among them) for a
cop the configuration disables, and a `rubocop:disable`/`enable` comment naming
a cop that is not enabled where the comment sits. RuboCop reports neither. It
names any file it could not read or parse, and lists every inline disable with
its reason.

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
layout        300  Kata/PairedBrackets 210, Layout/LineLength 90
next: structure — 184 offenses in 61 files; these mint the names `naming` then prices, so take them first
densest: app/models/account.rb (14)
```

Structure before naming, because doing naming first means renaming things the
structural pass is about to move; layout last, because every other stage moves
lines.

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

Double-quoted strings, `Metrics/MethodLength: 10` (a wrapped call counts as
one line) guarded by `Metrics/AbcSize: 17`, `CyclomaticComplexity: 7` and
`PerceivedComplexity: 8`, two-word names, `Metrics/ClassLength: 100`, `Metrics/ParameterLists: 4`, 120-column lines,
endless methods on one line, `rescue => error`, `NewCops: enable`, and inline
disables only with a reason. The core Layout cops stay on, except the four that
loop against Elegant's no-blank-lines rule. `rubocop -a` deletes no comment and
renames no ivar. See [config/default.yml](config/default.yml).

## Measured

`eval/run --kata PATH` scores a checkout: labelled cases per cop under the
shipped defaults, 400 labelled `-er`/`-or`/`-ar` names, the `rubocop-kata`
commands, and pinned codebases for offenses per kLOC and for what `-a` and `-A`
leave behind. [eval/results](eval/results/README.md) holds this release against
the previous one.

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
- **`data/agents.txt.gz`, `data/things.txt.gz`, `data/verbs.txt.gz`** — derived
  from [WordNet 3.0](https://wordnet.princeton.edu) by `script/wordnet`. WordNet 3.0
  Copyright 2006 by Princeton University, all rights reserved; its licence is
  reproduced in [data/WORDNET-LICENSE](data/WORDNET-LICENSE).
- **`data/supplement.txt`** and **`data/clippings.txt`** — this project's own
  additions, MIT.
