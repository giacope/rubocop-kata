# rubocop-kata

A RuboCop plugin that replaces a pile of linter gems and config with one dependency. Install it and your `.rubocop.yml` shrinks to project-specific overrides. Everything else comes from the gem: a curated stack of RuboCop extensions, opinionated style defaults, and thirty-seven house cops, ten of which wait in an opt-in strict Elegant Objects profile.

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

- **One dependency.** Bundles rubocop-rspec, rubocop-performance, rubocop-elegant, rubocop-packaging, and rubocop-thread_safety behind a single gem. Each runs where it applies: packaging only in a gem, RSpec only where RSpec runs.
- **Opinionated defaults.** Methods up to 10 lines and bounded by complexity, classes under 100, 4 parameters max, 120-column lines, double quotes, every pending cop kata reviewed. See [config/default.yml](config/default.yml).
- **Safe autocorrect, by structure.** `rubocop -a` runs a correction only when it changes layout (whitespace, line breaks, indentation, comment layout), delimiters or quotes — never the content of a string, heredoc or regexp — or swaps syntax for an exact equivalent that resolves no name or method the project could define, flips no receiver of `==`, merges or splits no condition, and moves, duplicates or drops no expression. It renames, anonymises or forwards no parameter either: an x-string, an `eval` string or `binding` may read a parameter by name (Opal's backtick JavaScript does), and a method's reflected signature (`Method#parameters`, YARD's `@param`) is part of its contract. [data/autocorrect.txt](data/autocorrect.txt) files each one under `layout`, `delimiter` or `equivalent` with its reason, and each correction a field test caught breaking code under `held`, with what it broke; every other correction waits for `rubocop -A`. So `rescue => e` is not rewritten to a `StandardError` the project may define, a guard clause is not hoisted past a `fail` the class may define, `not a < b` does not become `a >= b`, and a local is not inlined.
- **`-a` writes only what keeps the program's text.** Before `rubocop -a` writes a corrected file (or hands `--stdin` its result), kata parses it with Prism and compares the values of its string-like literals — strings, heredocs, x-strings, regexps and symbols, adjacent literals joined, each interpolation a placeholder whose own literals count on their own, quotes and delimiters ignored — with the original's. A `+` between two literals is a call, not a join: it builds a new, unfrozen String where adjacent literals were one frozen String (so `Layout/RedundantLineBreak`, which wrote one, reports the line break between adjacent literals but never joins it). A file the corrections would leave unparsable, or whose literal values they would change, is kept as it was, with one line on stderr naming the corrections it refused: `rubocop-kata: kept lib/sql.rb as it was: -a would have changed the literal on line 4 (refused: Layout/TrailingWhitespace)`. The report and the exit status then describe the file as it was kept: its offenses are reported as not corrected, so `rubocop -a && git diff --exit-code` fails on it as a plain run would. That catches a layout correction that strays into a literal (RuboCop's `Layout/TrailingWhitespace` inside a multi-line string, `Layout/IndentationWidth` inside a multi-line regexp) wherever it comes from. The same check, and the same held corrections, apply to `rubocop -x`, which kata runs as `-a` narrowed to layout; only `-A` writes everything it corrects. It needs RuboCop 1.91 or later, which writes each file once; when a plugin's extra Ruby extractor makes RuboCop write each pass to the file itself, kata checks the file it wrote and writes the original back. The guarantee is Ruby's semantics, not the text other tools read: a gemspec that greps `version.rb` for single quotes is the reason `Style/StringLiterals` leaves version files alone.
- **Rails out of the box.** In a Rails app kata knows the names Rails and its common gems dictate and the files the generators write, and relaxes nothing else.
- **Thirty-seven house cops.** Naming, dependency discipline, immutability, and data honesty in the Elegant Objects spirit — from `Kata/GoodClassName` to `Kata/FrozenState`. Ten of them run only under the [strict Elegant Objects profile](#strict-elegant-objects-profile), which also turns on a stricter reading of six others.

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

### What the plugin reads from the project

The plugin finds the project's root — the directory of the `.rubocop.yml`
that loads it, or else the nearest directory, from where RuboCop runs upwards,
that holds a `Gemfile`, `gems.rb`, a `*.gemspec` or `config/application.rb` —
so `rubocop` run from `app/models`, or from one gem of a monorepo, reads the
same project as one run from the root. It looks at three things there and shapes
the configuration to match:

- **A gem** (a `*.gemspec` in the root, or one directory down in a monorepo of
  gems) gets rubocop-packaging; anything else does not, since its cops are
  about how a gem is packaged.
- **RSpec** (a `.rspec`; `rspec`, `rspec-core` or `rspec-rails` in a Gemfile,
  lockfile or gemspec at the root or one directory down; or spec files that
  call `RSpec.describe`) gets rubocop-rspec; a Minitest suite, even one in
  `spec/`, does not.
- **Sorbet** (`sorbet` or `sorbet-runtime` in a Gemfile, lockfile or gemspec,
  or a `# typed:` sigil in the first library files) gets
  [config/sorbet.yml](config/sorbet.yml): `T.let(x, Type)`, `T.cast`,
  `T.must`, `T.unsafe` and `T.bind` read as `x`, `T.nilable(...)` and
  `T::Array[...]` as types, so a typed constructor or constant table is
  judged as its untyped twin.
- **A Rails app or engine** (`config/application.rb`, or any `lib/**/*.rb`
  or `<gem>/lib/**/*.rb` that subclasses `Rails::Engine` or calls
  `isolate_namespace`) gets
  [config/rails.yml](config/rails.yml) on top of the defaults: the method names
  Rails, Devise, Turbo and Pundit call by name (`default_url_options`,
  `after_sign_up_path_for`, `broadcast_target_default`,
  `permitted_attributes_for_create`, a namespace's `table_name_prefix`, a
  transaction record's `rolledback!`), `attributes` as the role suffix of a
  nested-attributes writer (`time_constraint_attributes=` is judged as
  `time_constraint`), `enum` mappings read as lookup tables,
  and the generated `bin/` and `db/` files kept out of `Kata/NoComments`. It
  relaxes no rule for code the application writes: an association chain, a nil
  check, a query on a model class or `Time.current` in a model are still
  offenses.

Each choice can be made by hand:

```yaml
plugins:
  - rubocop-kata:
      rails: false      # or true; also packaging: and rspec:
```

A `.jbuilder` template is presentation, so no Kata cop reads it. Vendored
and generated code is not the author's: `**/vendor/**` is excluded wherever
it sits, and so are a generator's templates (`lib/generators/**/templates/`,
`lib/templates/`: files copied into another project, often ERB, which hashira
and kimera skip too), and so is a library file with a grammar beside it (`parser.rb` next
to `parser.rl`, `.y`, `.racc`, `.treetop` or `.rex`) or a generator's marker
in the comment block it opens with ("generated by", "generated from",
`@generated`, "auto-generated", "autogenerated", "a generated file", "do not
edit", "DO NOT MODIFY", "has been generated"; stripe-ruby's "File generated
from our OpenAPI spec"). A class's documentation further down ("These are
generated by nodes") marks nothing; hashira reads the same marker. A project's own `AllCops: Exclude` adds to these paths rather than
replacing them (kata's `AllCops` merges `Exclude`; write
`inherit_mode: { override: [Exclude] }` under your `AllCops` to replace the
list). A path named on the command line is still inspected. In a monorepo of
engines, each engine's `<gem>/app/` is read like `app/` wherever a default
names `app/`: the files kata inventories (`OwnedPaths`), the controllers,
mailers, helpers and views `Kata/FrozenState` leaves to Rails, and the
Zeitwerk roots `Kata/ClassInModule` exempts (refinerycms's
`core/app/controllers/application_controller.rb`).

The project's own names are kata's to read, not to re-litigate. Each gem's
namespace and the Rails application's module give the project's root
constants (the `Kata` department's `Roots`: `RuboCop::Kata`, `Roda`,
`Nanoc::Core`). A gem's root is the namespace it defines, as its code spells
it, through its require path (`nanoc-core` → `nanoc/core` → `Nanoc::Core`) or
a file its entry file requires from its own `lib/` (`refinerycms-core.rb`
requires `refinery/core`: `Refinery::Core`; `test-prof` → `TestProf`;
`http` → `HTTP`), never a camelized gem name the code does not define. The
roots are what `Kata/GoodModuleName`, `Kata/GoodClassName` and
`Kata/ClassInModule` leave alone, and their snake-case name (in CamelCase
words or lowercased, `omni_auth_` or `omniauth_`) counts as a role prefix in
`Kata/GoodMethodName` and `Kata/GoodVariableName` (`pundit_policy_scope`,
`@_pundit_policy_scoped`: code mixed into host classes). The dependencies
(Gemfile, Gemfile.lock, gemspecs) name technologies: their segments are words
for `Kata/RealWords` (`@pagy`, `sshkit`), and a namespace one of them is
named for is theirs in `Kata/NoTypeCheck` however the project reopens it
(`Kata/NoTypeCheck`'s `Dependencies`). The segments of the project's own
constant names are words too (zeitwerk's `Cref` makes `cref` one). None of
these unbans a clipping: `args` and `str` stay clippings in a project that
names a class `Args`.

### The bundled rubocop-elegant

Kata reported four rubocop-elegant defects upstream
([#74](https://github.com/yegor256/rubocop-elegant/issues/74)–[#77](https://github.com/yegor256/rubocop-elegant/issues/77));
0.8.0 fixes them, but Kata's copies carry further fixes found on real codebases
(a heredoc inlined without its body, a lambda's brace, the indent after a
nested break), so `Kata/NoRedundantVariable`, `Kata/PairedBrackets`, and
`Kata/ClassInModule` stay, and the `Elegant/*` originals stay off.
`Elegant/MonotonicIndents` stays on, taught (in `lib/rubocop/kata/foreign_text.rb`)
to skip the lines that start inside an x-string, as it skips heredoc bodies:
opal's `%x{}` holds JavaScript, a backtick holds shell. rubocop-elegant's
configuration also switches off RuboCop cops RuboCop ships on; kata turns
`Style/ClassVars` (global mutable state every subclass shares; another class's
setting, `Minitest.class_variable_set(:@@installed_at_exit, …)`, passes) and
`Lint/NestedMethodDefinition` (a `def` inside a `proc` or `lambda`, a body for
`class_exec`, passes) back on, and a spec names the reason each of the others
stays off. So do
`Elegant/NoEmptyLinesInMethods` and `Elegant/NoEmptyLinesInBlocks`, which
deleted blank lines inside heredocs and multi-line strings — the text of the
program: `Kata/NoEmptyLinesInMethods` and `Kata/NoEmptyLinesInBlocks` leave
string content alone. They are
derived from rubocop-elegant under its MIT licence (see `LICENSE.txt`). CI tests
both the oldest releases the gemspec allows and the newest.

## The cops

A cop marked `strict` is off by default and runs under the [strict Elegant Objects profile](#strict-elegant-objects-profile).

| Cop | Default | What it enforces |
| --- | --- | --- |
| `Kata/GoodClassName` | on | A class names one object that exists in the model: no doers (agent nouns, read from WordNet data), no junk drawers (`Service`, `Util`, `Data`), no packing several concepts into one name (`CustomerOrderPayment`). `CreditCard` is one concept, and so is an acronym with its version (`HTML5`; `UTF8Input` is two); `Terms` holds those. A framework's suffix is a contract, its subject is not: `UsersController` is judged as `Users`, `ReportBuilderJob` as `ReportBuilder`, a helper's test as the helper (`InvoicesHelperTest` as `Invoices`). A class inherits the agent word of the superclass that chose it (`ActionHandler < Avo::Actions::ActionHandler`), and so does its test when that superclass is one of the `FrameworkSuperclasses` (`ScrubbingFormatterTest`, for a `Logger::Formatter`); `PaymentProcessorTest` is still a doer. An unknown `-er` word is a doer only when its stem is a verb (`Chunker`, `Upserter`), not a brand (`Instapaper`). A class under one of the `EntitySuperclasses` (`ApplicationRecord`) is a record of a thing (`Manufacturer`, `Teacher`), and one under a `ContractSuperclasses` entry (`RuboCop::Cop::Base`) is named by a contract. `AllowedNames` holds exception classes and the domain roles a model represents (`User`, `Owner`). A class is judged where it is defined, not in each file that reopens it only to nest classes inside, whatever superclass the reopening restates. A tool that resolves classes by their short name is a contract too: reek finds a smell detector by its class name, so a reek extension lists `Reek::SmellDetectors::BaseDetector` in `ContractSuperclasses`. |
| `Kata/GoodModuleName` | on | A module names a domain vocabulary (`Billing`, `AccessControl`), not an implementation category: no layer buckets (`Services`, `Helpers`, `Logic`), no vague shared namespaces (`Common`, `Shared`, `Core`), no doers. Rails helper modules (`InvoicesHelper`) are judged by their subject. A namespace reopened around the classes of many files is one decision, judged once: in the file named for it (`lib/flipper/services.rb`), else in its opening with the most statements. The project's root constants (`Faker`, `Nanoc::Core`) name the gem and pass. |
| `Kata/NoRedundantVariable` | on | A local assigned once and read once is inlined at its read when its name says nothing its value does not: a literal or bare read, a letter or a generic word (`result`), or a name the expression already spells (`user = User.find(id)`). A name that adds a word is an explanatory variable and stays (`subtotal = [...].max`), and so do a value that spans several lines (a heredoc's too), a regexp under a name that says what it matches, and a local whose inlining would pass the line limit, or cross a loop, a branch, or a side effect. Autocorrects, and keeps Ruby 3.1 shorthand intact. Fixed copy of `Elegant/NoRedundantVariable`. |
| `Kata/PairedBrackets` | on | Every bracket pairs on its line, or opens at line end and closes at line start. Autocorrects without drifting the indent, and never indents a line that starts inside a string, regexp, symbol, x-string or heredoc. Fixed copy of `Elegant/PairedBrackets`. |
| `Kata/NoEmptyLinesInMethods` | on | No blank line inside a method body; a method that needs paragraphs is several methods. Blank lines inside a heredoc or a multi-line string are its text, and stay. A blank line a `\` continues into (deleting it would join two statements) or one inside an `=begin` comment is reported but never deleted, here and by `Kata/NoEmptyLinesInBlocks`. Fixed copy of `Elegant/NoEmptyLinesInMethods`. |
| `Kata/NoEmptyLinesInBlocks` | on | No blank line inside a block, conditional, loop, `case` or `begin` outside any method, reported once however deeply it nests; inside a method, `Kata/NoEmptyLinesInMethods` reports it, once. The blank line between two `def`s in a block stays, as does string content. Excludes the test suite, where RSpec's own layout cops want the blank lines. Fixed copy of `Elegant/NoEmptyLinesInBlocks`. |
| `Kata/ClassInModule` | on | A class lives in a module, a class, or a compact namespace, never at the top level. A file directly in a Zeitwerk root (`app/models/account.rb`, and `lib/description_remover.rb` when `config/application.rb` autoloads `lib/` with `config.autoload_lib` or the autoload or eager-load paths) is exempt: Rails resolves it as a top-level constant by design. Reopening a core class (`class String`) is a monkey patch, and the message asks for a refinement or a decorator. The project's root class (`class Roda` in roda) is its one top-level name and passes, and a class reopened in several files is judged once, in the file named for it or its largest opening. Fixed copy of `Elegant/ClassInModule`; `Elegant/NoClassInModule`, which allowed only the compact form, is off. |
| `Kata/NoComments` | on | No prose comments; say it in the code. Code cannot cite an external constraint, so a block citing a URL, an issue (`rails/rails#123`), an RFC, a CVE or a version constraint (`RSpec < 3.0`, `Ruby >= 3.2`) is kept. Documentation is prose too, YARD tags and all; a gem that publishes its API documentation sets `AllowDocumentation: true` to keep a block whose next definition is public (a class, module, method, `attr_*`, `define_method` or a public constant, read across a Sorbet `sig`, a bare `memoize` line and RDoc's `##` blank line), in any markup, or any block carrying a YARD tag; a block in a method body or above a private method is prose either way. One block of consecutive comment lines is one offense. Kept too are magic comments in any form Ruby reads (`# frozen-string-literal: true`) and editor modelines, tool directives, the tool's name with its colon (`# rubocop:`, `# standard:`, `# steep:`, `# kimera:`, `# hashira:`, RBS, reek…; `AllowedPatterns` for more), and licence headers. Deleting a comment loses what it said, so it corrects only under `rubocop -A`. |
| `Kata/IoDiscipline` | on | No hidden I/O outside the test suite and the boot layer (as for `Kata/EnvDiscipline`, code outside every class, module and method is a script's boot layer, and so are a framework's boot hooks, `railtie.rb`, `engine.rb` and generators). No bare `puts`/`warn`/`pp`/`p`: write through an injected `@io` or an explicit receiver; the message names the stream the class already holds, or the seam to add (`def initialize(io: $stdout)`). A `p` given a block or no argument is not `Kernel#p` (Phlex's `<p>`). With `CheckEffects: true` (the strict profile) it reads the hidden I/O beyond the terminal too: bare `print`/`printf`; a global stream or service (`$stdout.puts`, `STDERR`, `Rails.logger`, `Rails.cache`; `Globals`) asks to be injected. A file, network or shell call whose target is written into the code — `File.write("log/audit.log", …)`, `YAML.load_file("config/x.yml")`, `Dir.pwd`, `Net::HTTP.post(URI("https://…"))`, `system("git", "fetch")`, `` `git rev-parse HEAD` `` (`Effects`, by what each reaches: a path, a URL, a command) — is hidden I/O; one whose target holds a variable, an instance variable, a method's value, an injected `base:`/`chdir:`, a constant another file defines, or a path anchored on the source file (`__dir__`, `__FILE__`) is the adapter whose job the effect is, and passes. Path arithmetic (`File.join`, `File.basename`) reaches nothing, and a constant or a command the project defines (rubycritic's `Options::File`, kimera's own `spawn`) is not Ruby's. |
| `Kata/ProsePlacement` | off | Sentence-length strings belong in the presentation layer. Enable with an `Include`/`Exclude` matching your layering. |
| `Kata/RealWords` | on | Every name segment is a word: English, an initialism (`tcp`, `ipv6`, `dkim`), a technology's name, or the platform's own spelling (`env`, `params`, `attr`, `io`). `errorcount` (a smash) fails, and so does every clipping, whichever dictionary lists it: `args`, `opts`, `src`, `impl`, `str`, `req`, `conn`, with the word named in the message (every word, for one like `dist`). `foo` is a placeholder. British and Commonwealth spellings are English (`organisation`, `colour`, `offence`, `labelled`, `artefact`, `dependant`, `judgement`, `enrolment`), and so are HTML's attribute names (`tabindex`, `srcset`, `aria-describedby`'s `describedby`); `Spelling: en-US` holds a codebase to American. The project's own name is a word (`kata` in rubocop-kata: the segments of its gemspec names and of a Rails application's module), and so are its dependencies' names (`pagy`, `sshkit`) and the segments of its constants (`cref`); a gem that depends on parser, rubocop-ast, rubocop or unparser speaks the parser's whole node types (`lvasgn`, `dstr`, `kwoptarg`) and names its callbacks for them (`on_str`, `on_op_asgn`), but `str`, `args` and `sym` stay clippings everywhere else. A word kata accepts is inflected where no dictionary spells its forms (`autoloaded`, `autocorrecting`, `favorited`), while `submited`, `readed` and `logined` stay typos: the dictionary spells `submitted` and `reading`, and a verb-particle noun (`login`, `setup`) inflects as the phrase (`logged in`). A method that calls `super` keeps its ancestor's name, and a stand-in for a message the project's code sends but never defines keeps the caller's. Tune via `Terms`/`BannedWords`/`AllowedNames`. |
| `Kata/GoodMethodName` | on | At most two words per method name (`MaxWords`), not counting a role prefix (`after_fork`), a role suffix (`file_of`) or a reviewed `Terms` entry; three or more words describe a missing object. A name chaining actions (`validate_and_save`) is two methods in one. Names minted by `attr_*`, `define_method`, `alias_method` and `alias` count. A joint (`and`, `or`, `then`) chains actions only between two words, so `then`, `or` and RuboCop's `on_and` are one word, and the atomic vocabulary (`compare_and_set`, `get_and_set`) ships in `AllowedNames`. A method that overrides one a project superclass or mixin defines is judged there, once; one that calls `super` overrides an ancestor's name, whoever owns it; and a stand-in for a message the project's code sends but never defines (a spec double of a Rails method that `lib/` calls) answers to the caller's name. A Minitest `test_` method in a test class goes unpriced. `AllowedPatterns` holds names a dispatcher dictates; Prism's `on_*_node_enter` listeners ship there. |
| `Kata/GoodVariableName` | on | The same rule for locals, parameters, ivars, class variables, and globals; `_name` and `@_name` stay exempt, and so do Ruby's predefined globals (`$VERBOSE`, `$PROGRAM_NAME`). |
| `Kata/BuilderNoun` | on | Builders named for what they return: `total`, not `calculate_total`. A method that overrides one the project's superclass or included module defines (an adapter implementing `get_all`) is judged once, where the name was chosen, and a method that issues a command anywhere in its body, conditional or not (`File.write`, a generator's `create_file`, `route` or `invoke`; `Commands`), is a side effect, named by its verb, as is a public method of a Rails generator or a Thor class (`StepSuperclasses`), which runs as a step. A predicate (`generate_ids?`) builds nothing. Tune via `BannedPrefixes`/`AllowedNames`. |
| `Kata/NoBooleanFlag` | on | No positional boolean arguments, and no positional parameter defaulting to one; split the method in two, one per value (a keyword flag is still a flag, and hashira's `control_parameter` reports it). `AllowedMethods` holds the calls whose boolean is a protocol or a value (`respond_to?(name, true)`, `fetch(:ssl, false)`, `flags.index(true)`, `eql?(false)`, `where`, `set`, RSpec's `eq`/`be`/`and_return`), and a boolean the callee stores or binds passes wherever it sits: after the name of the setting it fills (`auth_value_method :verify?, false`, `update_attribute(:spam, false)`), after a SQL string with a placeholder, in `receive(:x).with(true)`, as a hash value or through an attribute writer. |
| `Kata/ConstructorDiscipline` | on | `initialize` assigns, raises, or freezes — never computes. Shaping an argument (`Array(x)`, `name.to_s`, `items.dup`) and the object's own lock or empty collection (`Mutex.new`, `Set.new`) are assignment, and so are the object's own buffer and identity table (`+""`, `{}.compare_by_identity`); a clock, a random number or a client is a hidden dependency, and a parameter default is its seam. A guard may raise through the project's `RaisingMethods`. Assigning through the object's own writer (`self.project = project`) is assignment; `Kata/NoSetter` reports the writer. A constructor is one offense, at its first computation, naming every call to move (`Move \`on\` ×200 out of \`initialize\``). With `CheckPaths: true` (the strict profile), an `initialize` that branches on its arguments (`if formatted`, `case parts`, `if parts.size == 1`) is several constructors in one, reported once: keep one primary constructor and give each other way a class method that calls `new`; a guard that raises passes. A class method building with `allocate` bypasses `initialize`, a second primary constructor. |
| `Kata/NoClassMethodLogic` | on | A class method that only returns a literal, takes nothing and is defined by no other class (under `OwnedPaths`) asks for a constant; a hook that takes an argument, that subclasses override (`def self.for_class?(_model) = false`) or that sibling classes answer alike (each request class's `def self.label`, sent to whichever class a section holds) is the class's logic. Class methods construct (`build`, `parse`, `of`, `from_*`, `new`, `[]`, or any method whose result is a new instance of the class), answer a Ruby hook or protocol (`included`, `inherited`, `name`, `===`), or a serialization protocol (`load`/`dump`, `json_create`); instances do the work. A module of functions (`module_function`, `extend self`) is the same logic without a class, and is reported too. |
| `Kata/NoHashAsObject` | on | A hash with `MaxKeys`+ keys (default 4) wants to be an object. Keyword arguments (bare, not a braced hash passed last), a lookup table a constant names (its rows too, in a hash or an array), the mapping a `TableMethods` call takes (`enum` in the Rails profile), and the hash `to_h`/`as_json` return are exempt. |
| `Kata/ClockDiscipline` | on | No ambient clock (`Time.now`, `Time.zone.now`, `Date.current`, `Time.new`, `Process.clock_gettime`); inject a clock. With `CheckRandomness: true` (the strict profile), no ambient randomness either (`SecureRandom.hex`, `rand`, `Random.rand`, an unseeded `Random.new`, `sample`/`shuffle` without `random:`); inject a generator. A parameter default is the seam: `def stamp(now: Time.now)`, `def initialize(id = SecureRandom.uuid)`; a fallback (`now \|\| Time.now`) is not. A `rand` the project defines (ffaker's seeded `RandomUtils#rand`) and a draw one of its modules answers (`ArrayUtils.shuffle`) are its own. Code outside every class, module and method is a script's boot layer. |
| `Kata/JustifiedDirective` | on | An inline `rubocop:disable` says why after `--` (`# rubocop:disable Kata/GoodClassName -- Avo resolves the handler by this name`), so a false positive costs one reviewed line, not a per-file `Exclude`. |
| `Kata/EnvDiscipline` | on | `ENV`, and with `CheckSettings: true` (the strict profile) the application's configuration (`Rails.env`, `Rails.configuration`, `Rails.application.config`, `credentials`, `secrets`, `config_for`; `Settings`), are read only in the boot layer (`config/`, `config.ru`, `db/seeds*`, `db/migrate/`, `lib/tasks/`, rake files, Gemfiles, `bin/`, `exe/`, `script/`, `railtie.rb`, `engine.rb`, generators, a framework's `initializer`/`to_prepare`/`on_load` hooks) — or as a parameter default, which is the seam the cop asks for. Code outside every class, module and method is a script's boot layer too (an `eval/run` executable, a probe loaded with `-r`). |
| `Kata/FailFast` | strict | A `rescue` that neither re-raises (`raise`, `fail`, `retry`, `exit`, `abort`; `RaisingMethods`) nor turns the error into an object swallows it: an empty body, `nil`, `false`, a literal, `[]` or `{}`, logged first or not, or a log line alone (`rescue JSON::ParserError, IOError => error; @log.warn(...); {}`). Let it raise, or rescue the one error you expect and answer an object that says what failed (`rescue KeyError; Absent.new(key)` passes). A boolean is a question's answer when the rescue names the errors it expects (`rescue URI::InvalidURIError; false`), or sits in a predicate and names no bug (`def numeric? = Integer(x) rescue false`; `rescue NoMethodError` is a bug), and `==`/`<=>` answer a foreign object. The end of a stream or a process (`EOFError`, `Errno::EPIPE`, `Errno::ESRCH`), an empty queue's `ThreadError` and an optional library's `LoadError` (`ExpectedErrors`) are not failures; nor is a resource released on the way out (`socket.close rescue nil`, in an `ensure` or a rescue that re-raises). A `rescue` modifier catches every StandardError, bugs included, whatever it answers. The strict profile runs it in place of `Lint/SuppressedException` (which passes `rescue; nil`) and `Style/RescueModifier` (whose fix, `begin … rescue 0 end`, still swallows), and switches those two off. Excludes the test suite. |
| `Kata/ScopedResource` | strict | Whoever acquires a resource releases it, whatever happens in between. A lock taken and released by hand (`@lock.lock` … `@lock.unlock`; `acquire`/`release`, `checkout`/`checkin`) or a handle opened into a local and closed by hand (`socket = TCPSocket.new(...)` … `socket.close`; `disconnect`, `release`, `shutdown`), with the release outside an `ensure`, stays held when anything between them raises: hold it for a block (`@lock.synchronize { ... }`) or release it in `ensure`. A release in a `rescue` (the error path), or with no call between it and the acquire, passes; `File.open` and `Tempfile.open` are left to `Style/FileOpen`. |
| `Kata/NoSetter` | on | No `attr_writer`, `attr_accessor`, `def name=` or `define_method(:"#{name}=")`: an object takes its state in the constructor, and a change returns a new object. `[]=` is a collection's protocol and passes. |
| `Kata/NoGetter` | strict | No getters: a public `attr_reader` (or `attr`), or a method that only returns the field of its name (`def balance = @balance`), hands the object's data to whoever asks, and the logic about it moves there (`Label` building text from `customer.first_name` and `customer.last_name`). Tell the object what to do with its fields, or have it print itself to a medium it is given. `Struct.new` and `Data.define` mint a getter for every field: a data bag. A private or protected reader, in any spelling, is the object's own. |
| `Kata/NoReflection` | strict | No reflection on another object, which is hidden coupling: reading or writing its fields (`@order.instance_variable_get(:@total)`), calling a method by a name written in the code (`@record.send(:token)`, usually to reach a private one), building a constant's name at run time (`Object.const_get("Shop::#{kind}View")`, `"#{kind}View".constantize`). Ask through a public method, or map the names to objects. Dispatch on a name the code is handed (`public_send(field)`), an object reflecting on itself, and the boot layer pass. The strict profile runs it in place of `Style/Send`, whose advice (`__send__`, `public_send`) keeps the reflection. |
| `Kata/NoPublicConstant` | strict | No public constants as shared values: reading another of the project's classes' or modules' value constant (`Cart::MAX_ITEMS`, `Settings::TAX_RATE`) couples the reader to the value and scatters the logic that interprets it. Ask the owner what it means (`cart.full?`) and make the constant private. Only the project's own namespaces are judged (`Float::INFINITY` is Ruby's API); a class reading its own constant, a namespace, a class or an error, and `AllowedNames` (`VERSION`) pass. |
| `Kata/FieldCount` | strict | A class encapsulates at most `Max` fields (four): the instance variables its instance methods assign plus the fields its `attr_*` macros name, each once. A memoized answer (`@total ||= ...`) is a cache, not a field. More is several objects in one; group some into an object of their own. Rails controllers, mailers, helpers and views are not judged. |
| `Kata/PublicSurface` | strict | A class exposes at most `Max` public instance methods (four, "fewer than five"): its public `def`s and the methods its public `attr_*` macros mint. Ruby's protocols (`to_s`, `==`, `<=>`, `each`, `call`, `[]`; `Protocols`) and a dispatcher's callbacks (`on_*`; `AllowedPatterns`) are not counted, and Rails controllers, mailers, helpers and views are not judged. More is several objects in one; move some to an object of their own. |
| `Kata/FrozenState` | on | An instance variable is assigned in `initialize` (or `initialize_copy`, or a helper they call, followed through the project's superclasses, subclasses and mixins in other files) and nowhere else, and what it holds does not change afterwards (`@items << item`, `@index[k] = v`; a keyed cache is memoization). A name a collection's mutator shares with a collaborator's command (`insert`, `delete`, `clear`, `update`) changes state only on a collection the object built (`[]`, `Set.new`, `x.dup`) or uses as one: `@store.insert(row)` tells an injected store to act. Memoization passes: `@x ||= ...`, `@x = ... unless @x`, `if @x.nil?`, `@x = @x \|\| ...`, `return @x if defined?(@x)`. A hook a superclass's constructor calls (`setup`) is construction too (`ConstructorHooks` for a superclass elsewhere), and state set in a `define_method` block or by `instance_variable_set` counts. Rails controllers, mailers and helpers, which hand views their data through ivars, are excluded. Class-side state is not an instance's: `class << self`, `def self.x`, `class_methods do`, `module ClassMethods` and `module_function` modules are left to `ThreadSafety/ClassInstanceVariable`, and a module that is extended (`extend self`, `base.extend(X)`, `*ClassMethods`, `ClassInterface`) is told its state is class-level, not to move it to `initialize`. |
| `Kata/NoOutputArgument` | on | A method does not change what it was handed: `list << x`, `options.delete(:k)`, `hash[k] = v` and the other `MutatingMethods` on a parameter. Splats (`*args`, `**options`) are fresh collections, a parameter reassigned first (`list = list.dup`) is a copy, and `AllowedNames` holds the sinks (`io`, `out`, `buffer`, Rack's `env`). A method is one offense, at its first change, naming each parameter and what changes it (`` `[]=` ×10 changes the caller's `post` ``). `delete` with a character set (`text.delete("$,.")`, `"a-z"`) is `String#delete`, which returns a copy, and passes. |
| `Kata/CommandQuery` | on | A method answers or acts, never both. A `?` method is a query: no ivar assignment (memoizing the answer passes) and no `!` call on itself, its state or its parameters. With `CheckEveryQuery: true` (the strict profile) any method whose last expression is a value (a literal, a field, a sum, a lookup, a new object) is a query too, and a query sends no message to itself, its state, its parameters or a constant whose value it throws away (`@audit.record("balance read")`, `Rails.logger.info`): a statement nobody reads is there for its effect. A bang whose value the query reads (`policy!(user, record).show?`) is a lookup that raises, and a guard that raises (`raise`, `fail`, a bang on a constant as a guard's only branch) passes; so do work on the method's own locals (`lines << row`, a helper filling a local it built), iterations, and a method returning `self`. |
| `Kata/NoTypeCheck` | on | No `is_a?`, `kind_of?`, `instance_of?` or `respond_to?` against the project's own types; let polymorphism choose. A type is the project's when a class or module of that name is defined in the file or under `OwnedPaths` (`app/`, `lib/`), including a constant assigned `Class.new`, `Module.new`, `Struct.new` or `Data.define`, and is not one of Ruby's own (a shipped inventory of core, stdlib and default-gem constants, not whatever RuboCop happens to have loaded), and a `respond_to?` probe counts when one of the project's own classes defines the method publicly (a private helper never answers `respond_to?(:m)`; `respond_to?(:m, true)` counts private ones) and the receiver is not another library's constant (`::RSpec.respond_to?(:current_example)`) nor a literal, which is a core object (`"".respond_to?(:safe_constantize)`); a method defined in `refine String do` is `String`'s, and no object answers `respond_to?` for a refinement. A check against a type another library owns is the boundary where foreign data comes in, and passes, as do the conversion, iteration, IO and reflection protocols (`read`, `path`, `superclass`) and the bodies of `==`, `eql?`, `<=>`, `===`, `coerce` and `respond_to_missing?`. A name is resolved through the lexical nesting and is the project's only when the project defines that fully qualified name with a body, so reopening `module ActiveJob` does not make `ActiveJob::Base` the project's, while rubygems' own `Gem::Source` is; a class under a dependency's namespace (`Rack::Request` with rack in the Gemfile) stays the dependency's however the project reopens it. A type ladder in any spelling is the same question: `case x when Circle`, `case x in Circle`, `Circle === x`, `x.class == Circle`, `x.class.name == "Circle"`. A `respond_to?` probe of a method a public class of Ruby's standard library answers (and, in the Rails profile or a library whose gemspec depends on ActiveRecord, ActiveModel or ActiveSupport, one of Rails' frameworks, class attributes such as `defined_enums` included; [data/protocols](data/protocols), written by `script/protocols`) is a protocol. |
| `Kata/NoSingleton` | on | No `include Singleton`, and no class-level method caching an instance (`def self.instance = @instance ||= new`). A cache is judged by what it holds, the value its expression returns: a class-level cache of a value (`Set.new`, `Struct.new`, `Pathname.new`; `AllowedConstructors`), or of what is built from an instance (`Codelist.new(...).map { ... }`, `YAML.load(ERB.new(...).result)`), passes. With `CheckGlobals: true` (the strict profile) the framework's globals are singletons too: a subclass of `ActiveSupport::CurrentAttributes`, state kept in the thread, the fiber or the request store (`Thread.current[:user]`, `Fiber[:state]`, `RequestStore.store[:user]`; asking the thread its `name` passes), and a class-level setting behind `cattr_accessor`/`mattr_accessor`, their writers and thread variants (a reader is a constant). Code outside every class, module and method is a script's boot layer. |
| `Kata/NoNilArgument` | strict | No parameter that defaults to nil for the method to ask about (`coupon.nil?`, `coupon&.cents`, `coupon \|\| NONE`, `if coupon`, `coupon ||= ...`): that is two methods in one, the caller who has the value and the one who does not. Split them, or default to the value itself or a null object. A constructor's nil default kept in a field the class asks about (`@referrer.nil?`) is two objects in one. A nil default the method only passes on is the callee's, and `AllowedMethods` holds the signatures Ruby and Rails dictate (`as_json(options = nil)`). |
| `Kata/NoNilReturn` | strict | A method never returns nil, on any code path: no literal `nil` or `return nil`, no lookup whose nil it passes on (`detect`, `find` with a block, `find_by`, `first`, `last`, `min`, `max`, `sample`, `[]`, `dig`, `match`, `index`, `presence`, `try`, `&.`), and no missing branch of an `if`, `unless` or `case` whose other branches answer with a value (`@items[code] if @open`). Return a null object, or fail fast (`fetch`). A slice (`rows[1..]`) and a hash built with a default answer every key; a conditional command (`@mailer.deliver if @on`), a predicate, a writer and a method forwarding the protocol it is named after (`def first = @rows.first`) pass. A block's literal `nil` is reported too. The strict profile runs it in place of `Elegant/NoNilReturn`, which sees only the literal. |
| `Kata/NoHardWiring` | strict | An instance method does not build one of the project's classes as a collaborator: an object used for its effects (`Gateway.new("live").charge(@cents)`, built from literals, from nothing, or from a constant or global the method does not own; a local whose message's value is thrown away; a bang or a writer), kept in a field (`@gateway ||= Gateway.new`), or handed on as another object's dependency (`Order.new(Gateway.new("live"))`). No caller can hand it another implementation, and its test has to stub `new`. Take the collaborator in the constructor; a parameter default (`gateway = Gateway.new("live")`) is the seam, Elegant Objects' secondary constructor. A value wrapper built from the method's own values (arguments, locals, fields, the class's own constants, literals) and asked a question on the spot is composition and passes (`Nesting.new(node).qualified`, `def csv = Table.new(COLUMNS, @rows, @separator).csv`), and so do an object built to be returned or passed to a method (`Cart.new(@items + [item])`, a local filled and returned), the class building itself, constructors, class methods and the composition roots a framework instantiates (controllers, jobs, mailers, workers, rake tasks, `bin/`, `config/`), and Ruby's and other libraries' classes, which are values or boundaries. |

## Strict Elegant Objects profile

kata's defaults judge what most Ruby can meet. The strict profile holds a
project to the whole of Elegant Objects: inherit it on top of the plugin.

```yaml
plugins:
  - rubocop-kata

inherit_gem:
  rubocop-kata: config/strict.yml
```

It switches on the ten house cops kata ships off — `Kata/FailFast`,
`Kata/ScopedResource`, `Kata/NoNilArgument`, `Kata/NoNilReturn`,
`Kata/NoHardWiring`, `Kata/NoGetter`, `Kata/FieldCount`,
`Kata/PublicSurface`, `Kata/NoPublicConstant` and `Kata/NoReflection` — and
the stricter reading of six it ships on: `Kata/IoDiscipline`'s
`CheckEffects` (files, the network, the shell, global streams and services,
`print`), `Kata/ClockDiscipline`'s `CheckRandomness`,
`Kata/EnvDiscipline`'s `CheckSettings` (the framework's configuration),
`Kata/NoSingleton`'s `CheckGlobals` (`CurrentAttributes`, thread and request
stores, `mattr_accessor`), `Kata/CommandQuery`'s `CheckEveryQuery` (every
method that answers a value, not only `?` methods) and
`Kata/ConstructorDiscipline`'s `CheckPaths` (one primary constructor, no
`allocate`). It switches off the four cops a strict one replaces, so nothing
is reported twice: `Lint/SuppressedException` and `Style/RescueModifier`
(`Kata/FailFast`), `Elegant/NoNilReturn` (`Kata/NoNilReturn`) and
`Style/Send` (`Kata/NoReflection`). Any of them can still be turned back off
in the project's own `.rubocop.yml`. The profile names the plugin itself, so
it also works where the project's `plugins:` sit in another inherited file. Expect a large backlog on most code:
the profile flags inelegant code by design.

## Dead configuration

`doctor` reports configuration that no longer does anything: an entry in
`.rubocop.yml` or any file it inherits (`.rubocop_todo.yml` among them) for a
cop the configuration disables, a `rubocop:disable`/`enable` comment naming
a cop that is not enabled where the comment sits, and `AllCops:
DisabledByDefault: true`, under which RuboCop runs only the cops the
project's files enable by name, so kata's cops are off until each is enabled
by name (`Kata/GoodMethodName:` with `Enabled: true`). RuboCop reports none of
these. It names any file it could not read or parse, and lists every inline
disable with its reason.

```sh
bundle exec rubocop-kata doctor          # or: doctor path/to/project
```

```
.rubocop.yml:20: `Elegant/GoodMethodName` is disabled by the configuration this project inherits; the entry does nothing.
lib/registry.rb:44: the directive names `Elegant/GoodMethodName`, which is not enabled here; the comment does nothing.
2 dead entries
```

It exits non-zero when it finds something — a dead entry, or an inline
disable without a reason, which `Kata/JustifiedDirective` reports — so it can
gate CI. An entry for a cop RuboCop renamed is named as a rename ("`Naming/PredicateName`
was renamed to `Naming/PredicatePrefix`; rename the entry"), never as dead:
RuboCop applies it to the new name with a warning, or refuses to load the
configuration, and doctor then says to rename it in `.rubocop.yml`.

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

`plan` always applies kata's defaults beneath the project's own configuration,
so on a project that has not named the plugin yet it previews what adopting kata
would report, instead of running Kata cops with no configuration at all.

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
endless methods on one line, `rescue => error` (reported, not renamed), and inline
disables only with a reason. `NewCops` stays off: the pending cops kata reviewed
are listed one by one, so a RuboCop upgrade adds no autocorrect nobody has
read. The core Layout cops stay on, except the five that loop against the
no-blank-lines rule and `Layout/MultilineOperationIndentation`, whose two
styles both indent a multi-line `if` condition by a step `Elegant/MonotonicIndents`
rejects. `rubocop -a` is an allowlist admitted by structure, not by
evidence: a suite that stays green proves a correction safe on the code it met,
not on the next codebase ([data/autocorrect.txt](data/autocorrect.txt);
`script/autocorrect` writes [config/autocorrect.yml](config/autocorrect.yml)
from it, and `eval/run` runs the corpora's suites to find bugs in what the rule
admits). So `-a` deletes no comment, renames no ivar, rescue variable or
parameter, swaps no name for one the project may define, moves no expression,
keeps RBS and Steep annotations, and writes no file whose string, regexp or
symbol values it would change; everything else is `-A`. See
[config/default.yml](config/default.yml).

## Measured

The six object-discipline cops (`NoSetter`, `FrozenState`, `NoOutputArgument`,
`CommandQuery`, `NoTypeCheck`, `NoSingleton`) and `NoClassMethodLogic`'s module
rule shipped with a blind precision check: an independent rater, who saw only
the shuffled offenses and the codebases, labelled up to 25 per cop on faraday,
rubygems.org, hashira and kimera:

| Cop | Offenses | Sampled | Actionable | Default |
| --- | --- | --- | --- | --- |
| `Kata/NoSetter` | 50 | 25 | 14 (0.56) | on |
| `Kata/FrozenState` | 93 | 25 | 18 (0.72) | on |
| `Kata/NoOutputArgument` | 75 | 25 | 21 (0.84) | on |
| `Kata/CommandQuery` | 10 | 10 | 10 (1.00) | on |
| `Kata/NoTypeCheck` | 332 | 25 | 1 (0.04) | on, own types only |
| `Kata/NoSingleton` | 4 | 4 | 2 (0.50) | on |
| `Kata/NoClassMethodLogic`, modules | 67 | 25 | 23 (0.92) | on |

The per-corpus counts and every label are in
[eval/results](eval/results/README.md#object-discipline-cops).

Whether a cop is on is decided by the philosophy, not by that number. The
rater asked whether a reviewer would ask for the change, which carries
convention back in ("standard Rails", "idiomatic"). A cop is on when it reads
the code correctly and its advice is what Elegant Objects asks for; where an
offense was a misread, the cop changes. `NoTypeCheck` was off because most
checks it reported tested a class another library owns, where polymorphism
cannot reach; scoped to the project's own types, it reports only the checks
polymorphism would remove.

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
- **`data/supplement.txt`**, **`data/clippings.txt`** and **`data/actions.txt`** —
  this project's own additions, MIT.
