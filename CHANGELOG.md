# Changelog

## [Unreleased]

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
