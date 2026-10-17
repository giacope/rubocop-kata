# Evaluation results

`before.json` is `main` at `719080f`, `after.json` is this branch at `d6cf35c`,
both run by `eval/run` with rubocop 1.92.0 and the released rubocop-elegant
0.8.0, the versions a fresh `bundle install` resolves. Regenerate with:

```sh
eval/run --kata ../main-checkout --out eval/results/before.json
eval/run --kata .                --out eval/results/after.json
eval/run --compare eval/results/before.json eval/results/after.json
```

What the sections measure:

- **Snippet cases** (`eval/cases/*.yml`): must-flag and must-not-flag Ruby,
  one file per gap, run as a project runs them, with `plugins:
  [rubocop-kata]` and nothing else. Three still fail, on purpose:
  `job-subject-allowed` (`InvoiceReminderJob`: WordNet reads *reminder* as
  "a message that reminds", a doer; the dataset calls it ambiguous),
  `job-doer-subject-flagged` (`ReportGeneratorJob`: WordNet's dominant
  *generator* is an apparatus, so the rule misses it), and
  `disable-all-flagged` (a `rubocop:disable all` silences every cop on its own
  line, this one included; `rubocop-kata doctor` lists it instead). A case
  with `enable: true` switches its cop on, to pin a cop that ships off.
- **Names** (`eval/names.yml`): 400 class names ending in -er/-or/-ar,
  labelled before the rule changed: 213 doers (26 of them people's roles),
  161 things, 26 ambiguous (scored apart). A third is held out by CRC32 and was
  not inspected name by name while tuning. *raw* clears `AllowedNames`,
  `Suffixes` and `Terms`, so it scores the doer rule alone; *shipped* is what
  users get, where domain roles (`User`) and framework suffixes are policy.
  The raw rule's false positives went from 68 to 2 (`Creditor`, `Header`); its
  recall fell from 0.98 to 0.94 (holdout 0.89): where WordNet's dominant sense
  is a thing or never uses the verb, a doer now passes. Read once at the end,
  the holdout misses were Assembler, Benchmarker, Decoder, Escalator,
  Generator, Lexer, Merger and Refresher, and its one false positive Header
  (which the shipped `AllowedNames` covers).
- **Shipped configuration**: facts read from the resolved config of a bare
  project. `AllowedNames` 45 per cop, duplicated for modules, is now one
  9-entry list (exception classes, domain roles, three words with an equally
  common thing reading, and `Header`). Framework names moved to
  `ContractSuffixes` (not shown in `class_suffixes`, which counts the test
  suffixes).
- **Corpora** (`eval/corpora.yml`): faraday `lib`, rubygems.org `app`+`lib`
  with a bare kata config; hashira and kimera `lib` with their own config.
  *Autocorrect safety* copies each tree, runs `rubocop -a` or `-A`, then
  counts files that no longer parse, comment lines kept (all, YARD tags,
  encoding magic), and faraday's 652 specs. rubygems.org's suite needs
  PostgreSQL and is not run.
- **MethodLength by CountAsOne** reports the length cop under three counting
  rules. With the limit at 10 the fold matters little (faraday 20 vs 22
  without any folding, rubygems.org 143 vs 203).

## Object-discipline cops

Six cops (`Kata/NoSetter`, `Kata/FrozenState`, `Kata/NoOutputArgument`,
`Kata/CommandQuery`, `Kata/NoTypeCheck`, `Kata/NoSingleton`) and a new rule in
`Kata/NoClassMethodLogic` (a module declared with `module_function` or `extend
self`) were measured before their defaults were chosen. The bar: a cop is on by
default only if at least one in three of its offenses is actionable.

Each cop ran with `--only` over the four corpora (the same paths and configs as
the corpus section: faraday and rubygems.org bare, hashira and kimera with their
own `.rubocop.yml`). Up to 25 offenses per cop were drawn with a fixed seed
(`Random.new(42)`), shuffled, and labelled by an independent rater: a separate
model instance given only the codebase, file and line of each offense, each
rule's one-paragraph statement, and the rubric. It did not see the cops' code or
why their exemptions exist. The rubric:

- **TP**: a genuine instance of the problem the rule describes, where the
  rule's remedy would be a reasonable change to ask for in review.
- **FP**: not an instance (the rule misread the code), covered by the rule's
  own stated exemptions, or dictated by an external contract (a framework or
  library API, a protocol, a Ruby requirement), so the remedy is not available.
- **UNSURE**: cannot decide from the code and the repository (none were).

Every label, with the rater's reason, is in
[object_discipline_labels.json](object_discipline_labels.json).

| Cop | faraday | rubygems.org | hashira | kimera | Total | Sampled | TP | Precision | Default |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Kata/NoSetter` | 27 | 19 | 0 | 4 | 50 | 25 | 14 | 0.56 | on |
| `Kata/FrozenState` | 10 | 29 | 23 | 31 | 93 | 25 | 18 | 0.72 | on |
| `Kata/NoOutputArgument` | 7 | 19 | 11 | 38 | 75 | 25 | 21 | 0.84 | on |
| `Kata/CommandQuery` | 0 | 8 | 0 | 2 | 10 | 10 | 10 | 1.00 | on |
| `Kata/NoTypeCheck` | 67 | 41 | 112 | 112 | 332 | 25 | 1 | 0.04 | off |
| `Kata/NoSingleton` | 2 | 2 | 0 | 0 | 4 | 4 | 2 | 0.50 | on |
| `Kata/NoClassMethodLogic`, modules | 1 | 2 | 31 | 33 | 67 | 25 | 23 | 0.92 | on |

What the false positives were:

- **NoSetter** (11): ActiveRecord attribute writers and nested-attribute
  writers (`conditions_attributes=`), which Rails mass assignment calls; a
  setter a framework calls (Avo's `item=`, Faraday's middleware `Env#body=`);
  kimera's process-wide runtime switch. Faraday's module- and class-level
  configuration setters were judged true positives.
- **FrozenState** (7): hashira's once-only walks, guarded by a flag
  (`return if @_walked; @_walked = true; ...`), whose helpers fill several
  caches; the rater read them as memoization, which the cop only recognises
  when the guard tests the variable being assigned. Also kimera's runtime
  switch.
- **NoOutputArgument** (4): a shared thread-safe `Queue` popped by workers,
  Rails' `append_info_to_payload` hook, and two writes into RSpec's
  `filtered_examples`. An earlier run also reported Faraday and Rack
  middleware writing `env[:body]`, which their protocol requires; `env` joined
  `AllowedNames` before the sample was drawn.
- **CommandQuery** (0): an earlier run also flagged `policy!(user,
  record).show?`, a lookup that raises rather than a command; a bang call
  whose value the query reads now passes, before the sample was drawn.
- **NoTypeCheck** (24 of 25): type checks on Prism or Parser AST nodes, a
  closed set of classes another library owns (14); validation of parsed JSON,
  request params and options at a boundary, where the check is the conversion
  the remedy asks for; feature detection on other libraries (RubyGems,
  Minitest, Rails, Faraday adapters). Nothing in the call distinguishes these
  from the checks polymorphism would remove, so the cop ships off.
- **NoSingleton** (2 of 4): a cached configuration value
  (`ConnectionOptions.new`) and a frozen, stateless validator. Four offenses
  is a small sample; it clears the bar, but with little margin of evidence.
  Before the sample was drawn, a class-level cache of a value
  (`@members ||= Set.new(...)`) stopped counting (`AllowedConstructors`).
- **NoClassMethodLogic, modules** (2): a null object built as a module, and
  `Faraday::Utils`, a public API.

What turning the on-by-default cops on adds to the two codebases that already
run kata (offenses with their own configuration): hashira gains 65
(FrozenState 23, NoOutputArgument 11, NoClassMethodLogic 31), kimera 108
(FrozenState 31, NoOutputArgument 38, NoSetter 4, CommandQuery 2,
NoClassMethodLogic 33). On rubocop-kata itself the on-by-default cops found
six offenses, each fixed in the code: `Checkup#files` and `Ledger#nodes` no
longer fill an accumulator parameter, `PairedBrackets` keys its string cache
by the source instead of resetting it, the eval suite's corpus threads return
their results instead of popping a shared queue into a shared hash, and its
case loader no longer deletes a key from the case it was handed.

The R15 snippet cases pin each cop's flagged and allowed shapes, and that
`Kata/NoTypeCheck` is off unless enabled; a case's `enable: true` turns its cop
on in that case's config. All 24 pass; across every gap 208 of 211 cases
pass, the three failing being the ones listed above.

## Why methods may run to 10 lines and names to two words

A blind readability study (the items and ratings are in hashira, under
`eval/results/fragmentation/`) drew two samples. Each held 30 entry methods,
with their same-class helpers, from kimera and hashira, two codebases written
to kata's five-line, one-word rules, and 30 from rubocop, faraday and
rubygems.org. Each sample had two raters, who agreed on the fragmentation
call for 55 and 54 of 60 items.

| Sample | Over-fragmented, house | Over-fragmented, control | Readability, house / control | Names, house / control | Lines per method, house / control |
| --- | --- | --- | --- | --- | --- |
| 1 | 15, 14 of 30 | 2, 0 of 30 | 3.00, 3.03 / 3.90, 3.83 | 2.57, 2.47 / 4.17, 4.00 | 3.30 / 6.35 |
| 2 | 16, 14 of 30 | 1, 1 of 30 | 2.83, 3.07 / 3.97, 4.07 | 2.47, 2.97 / 3.97, 4.17 | 3.03 / 6.22 |

(Two numbers are the two raters; scores are 1 to 5.) The study cannot separate
the rules from the codebases that followed them, but it points one way. The
length limit returns to RuboCop's 10, and the complexity cops guard logic
density at RuboCop's defaults (AbcSize 17, CyclomaticComplexity 7,
PerceivedComplexity 8). Two-word names are allowed. Measured on these
corpora, MethodLength offenses fall from 61 to 20 on faraday and from 458 to
143 on rubygems.org; CyclomaticComplexity and PerceivedComplexity add 15
offenses on faraday and 31 on rubygems.org; hashira and kimera gain none.
Two-word names take GoodMethodName from 109 to 27 on faraday and from 1,293
to 613 on rubygems.org, and GoodVariableName from 79 to 4 and from 600 to 137
(round two to this branch). The R13 and R14 cases pin what still fails:
three-word and chained names, smashes, and long or branching methods.

## Offenses this branch adds to hashira and kimera at their branch HEADs

Read-only runs at hashira `e7b3c07` and kimera `5f0488f`, with their own
configuration, comparing main's kata, round two (`6135b51`), and this branch:

| Repo | main | round two | this branch | Added over main, by cop |
| --- | --- | --- | --- | --- |
| hashira | 2 | 7 | 7 | AbcSize 3, ClockDiscipline 2 |
| kimera | 0 | 60 | 59 | RealWords 45, ClockDiscipline 8, Layout/BlockAlignment 4, AbcSize 2 |

The round-three changes add nothing to either; they remove kimera's one
GoodMethodName offense (`discard_pool!`).



## Snippet cases (shipped defaults)

| Gap | Passed |
| --- | --- |
| R1 | 5 → 24 of 24 |
| R2 | 5 → 13 of 13 |
| R3 | 35 → 50 of 50 |
| R4 | 8 → 21 of 21 |
| R5 | 13 → 29 of 31 |
| R6 | 3 → 6 of 6 |
| R7 | 0 → 3 of 3 |
| R9 | 1 → 4 of 5 |
| R11 | 0 → 1 of 1 |
| R13 | 11 → 17 of 17 |
| R14 | 1 → 3 of 3 |
| extra | 13 → 13 of 13 |
| all | 95 → 184 of 187 |

## Still failing

- `job-subject-allowed`: expected no offense, found 1
- `job-doer-subject-flagged`: expected an offense, found none
- `disable-all-flagged`: expected an offense, found none

## -er/-or/-ar names (400 labels)

| Variant | Split | precision | recall | fp | fn | ambiguous_flagged | roles_flagged |
| --- | --- | --- | --- | --- | --- | --- | --- |
| raw | dev | 0.7447 → 0.9928 | 0.979 → 0.965 | 48 → 1 | 3 → 5 | 13 → 10 | 15 → 17 |
| raw | holdout | 0.7753 → 0.9841 | 0.9857 → 0.8857 | 20 → 1 | 1 → 8 | 11 → 8 | 9 |
| raw | all | 0.7545 → 0.9901 | 0.9812 → 0.939 | 68 → 2 | 4 → 13 | 24 → 18 | 24 → 26 |
| shipped | dev | 0.7665 → 0.9926 | 0.8951 → 0.9441 | 39 → 1 | 15 → 8 | 11 → 8 | 12 → 14 |
| shipped | holdout | 0.7625 → 1.0 | 0.8714 | 19 → 0 | 9 | 10 → 7 | 8 |
| shipped | all | 0.7652 → 0.9949 | 0.8873 → 0.9202 | 58 → 1 | 24 → 17 | 21 → 15 | 20 → 22 |

Raw rule on the dev split. False positives: Creditor. False negatives: Accumulator, Differ, Linter, Registrar, Requester.

## Shipped configuration

| Fact | Value |
| --- | --- |
| kata_cops | 18 → 19 |
| kata_cops_enabled | 17 → 18 |
| class_allowed_names | 45 → 9 |
| module_allowed_names | 45 → 9 |
| allowed_names_total | 90 → 18 |
| allowed_names_distinct | 45 → 9 |
| class_suffixes | 4 |
| banned_words | 16 → 0 |
| core_cops_silenced | 25 → 15 |
| layout_cops_silenced | 14 → 4 |
| no_comments_safe_autocorrect | true → false |
| no_comments_allow_documentation | false → true |
| inline_disable_banned | true → false |
| memoized_ivar_autocorrect | true → false |
| method_length_count_as_one | ["array", "hash", "heredoc", "method_call"] |
| abc_size_max | 50 → 17 |

## CLI

| Case | Result |
| --- | --- |
| plan-under-lang-c | fail → pass |
| plan-stages-every-kata-cop | fail → pass |
| doctor-reads-inherit-from | fail → pass |
| doctor-reports-unparsable-file | fail → pass |
| doctor-reports-undecodable-file | fail → pass |
| doctor-lists-reasoned-disables | fail → pass |
| doctor-clean-project | pass → pass |
| plan-clean-project | pass → pass |

## Corpora

| Corpus | Offenses | PerKLOC |
| --- | --- | --- |
| faraday | 1958 → 990 | 501.3 → 253.5 |
| rubygems.org | 7159 → 5710 | 275.0 → 219.4 |
| hashira | 2 → 9 | 0.3 → 1.1 |
| kimera | 0 → 58 | 0.0 → 4.8 |

## Autocorrect safety

| Corpus | Mode | Unparsable | Comments kept | YARD kept | Encoding kept | Test failures |
| --- | --- | --- | --- | --- | --- | --- |
| faraday | -a | 0 → 0 | 61/1068 → 1067/1068 | 28/257 → 257/257 | 0/0 → 0/0 | 0 → 0 |
| faraday | -A | 0 → 0 | 61/1068 → 844/1068 | 28/257 → 257/257 | 0/0 → 0/0 | 24 → 0 |
| rubygems.org | -a | 0 → 0 | 557/1370 → 1368/1370 | 0/12 → 12/12 | 0/0 → 0/0 | n/a → n/a |
| rubygems.org | -A | 0 → 0 | 558/1370 → 757/1370 | 0/12 → 12/12 | 0/0 → 0/0 | n/a → n/a |

## Metrics/MethodLength offenses by CountAsOne

| Corpus | kata | without_method_call | none |
| --- | --- | --- | --- |
| faraday | 61 → 20 | 66 → 20 | 70 → 22 |
| rubygems.org | 458 → 143 | 502 → 159 | 569 → 203 |
| hashira | 0 | 0 | 0 |
| kimera | 0 | 6 → 0 | 13 → 0 |

## faraday: offenses per kLOC by cop

| Cop | Before | After | Delta |
| --- | --- | --- | --- |
| Elegant/MonotonicIndents | 7.42 | 7.42 | 0.0 |
| Elegant/NoClassInModule | 9.22 | 0.0 | -9.22 |
| Elegant/NoEmptyLinesInBlocks | 8.96 | 8.96 | 0.0 |
| Elegant/NoEmptyLinesInMethods | 26.63 | 26.63 | 0.0 |
| Elegant/NoNilReturn | 1.54 | 1.54 | 0.0 |
| Kata/ConstructorDiscipline | 13.57 | 12.29 | -1.28 |
| Kata/EnvDiscipline | 0.26 | 0.26 | 0.0 |
| Kata/GoodClassName | 1.02 | 1.79 | 0.77 |
| Kata/GoodMethodName | 25.09 | 6.91 | -18.18 |
| Kata/GoodModuleName | 1.28 | 1.28 | 0.0 |
| Kata/GoodVariableName | 20.23 | 1.02 | -19.21 |
| Kata/IoDiscipline | 0.51 | 0.51 | 0.0 |
| Kata/JustifiedDirective | 0.0 | 0.77 | 0.77 |
| Kata/NoClassMethodLogic | 5.38 | 5.12 | -0.26 |
| Kata/NoComments | 256.78 | 57.09 | -199.69 |
| Kata/NoHashAsObject | 0.77 | 0.51 | -0.26 |
| Kata/NoRedundantVariable | 3.33 | 3.33 | 0.0 |
| Kata/PairedBrackets | 6.14 | 6.14 | 0.0 |
| Kata/RealWords | 8.19 | 10.75 | 2.56 |
| Layout/ArgumentAlignment | 6.14 | 6.14 | 0.0 |
| Layout/LineEndStringConcatenationIndentation | 1.02 | 1.02 | 0.0 |
| Layout/MultilineAssignmentLayout | 7.68 | 7.68 | 0.0 |
| Layout/MultilineMethodCallIndentation | 0.0 | 0.77 | 0.77 |
| Layout/RedundantLineBreak | 2.56 | 2.56 | 0.0 |
| Metrics/AbcSize | 0.0 | 3.07 | 3.07 |
| Metrics/ClassLength | 1.02 | 1.02 | 0.0 |
| Metrics/CyclomaticComplexity | 0.0 | 2.05 | 2.05 |
| Metrics/MethodLength | 15.62 | 5.12 | -10.5 |
| Metrics/PerceivedComplexity | 0.0 | 1.79 | 1.79 |
| Naming/BlockForwarding | 6.66 | 6.66 | 0.0 |
| Naming/MemoizedInstanceVariableName | 3.84 | 3.84 | 0.0 |
| Style/ArgumentsForwarding | 7.17 | 7.17 | 0.0 |
| Style/DisableCopsWithinSourceCodeDirective | 1.02 | 0.0 | -1.02 |
| Style/ImplicitRuntimeError | 1.02 | 1.02 | 0.0 |
| Style/Send | 3.84 | 3.84 | 0.0 |
| Style/StringLiterals | 34.31 | 34.31 | 0.0 |
| Style/StringLiteralsInInterpolation | 1.02 | 1.02 | 0.0 |
| ThreadSafety/ClassAndModuleAttributes | 2.56 | 2.56 | 0.0 |
| ThreadSafety/ClassInstanceVariable | 4.1 | 4.1 | 0.0 |
| ThreadSafety/MethodRedefinition | 1.02 | 1.02 | 0.0 |

## rubygems.org: offenses per kLOC by cop

| Cop | Before | After | Delta |
| --- | --- | --- | --- |
| Elegant/MonotonicIndents | 6.76 | 6.76 | 0.0 |
| Elegant/NoEmptyLinesInBlocks | 12.02 | 12.02 | 0.0 |
| Elegant/NoEmptyLinesInMethods | 37.61 | 37.61 | 0.0 |
| Kata/BuilderNoun | 0.46 | 0.46 | 0.0 |
| Kata/ClassInModule | 5.57 | 0.88 | -4.69 |
| Kata/ClockDiscipline | 1.54 | 2.15 | 0.61 |
| Kata/ConstructorDiscipline | 4.3 | 4.03 | -0.27 |
| Kata/EnvDiscipline | 0.81 | 0.81 | 0.0 |
| Kata/GoodClassName | 5.8 | 6.91 | 1.11 |
| Kata/GoodMethodName | 48.98 | 23.55 | -25.43 |
| Kata/GoodModuleName | 0.81 | 0.88 | 0.07 |
| Kata/GoodVariableName | 23.05 | 5.26 | -17.79 |
| Kata/IoDiscipline | 1.27 | 1.27 | 0.0 |
| Kata/JustifiedDirective | 0.0 | 1.31 | 1.31 |
| Kata/NoBooleanFlag | 0.19 | 0.19 | 0.0 |
| Kata/NoClassMethodLogic | 7.11 | 7.03 | -0.08 |
| Kata/NoComments | 30.5 | 24.05 | -6.45 |
| Kata/NoHashAsObject | 1.58 | 1.58 | 0.0 |
| Kata/NoRedundantVariable | 4.46 | 4.46 | 0.0 |
| Kata/PairedBrackets | 8.18 | 7.61 | -0.57 |
| Kata/RealWords | 10.41 | 12.79 | 2.38 |
| Layout/ArgumentAlignment | 3.23 | 3.23 | 0.0 |
| Layout/ArrayAlignment | 1.15 | 1.15 | 0.0 |
| Layout/BlockAlignment | 0.0 | 0.81 | 0.81 |
| Layout/HashAlignment | 5.11 | 5.11 | 0.0 |
| Layout/LineEndStringConcatenationIndentation | 2.61 | 2.61 | 0.0 |
| Layout/LineLength | 7.64 | 7.64 | 0.0 |
| Layout/MultilineAssignmentLayout | 5.49 | 5.49 | 0.0 |
| Layout/RedundantLineBreak | 4.34 | 4.34 | 0.0 |
| Lint/UselessConstantScoping | 1.19 | 1.19 | 0.0 |
| Metrics/AbcSize | 0.04 | 6.34 | 6.3 |
| Metrics/ClassLength | 1.04 | 1.04 | 0.0 |
| Metrics/CyclomaticComplexity | 0.04 | 0.81 | 0.77 |
| Metrics/MethodLength | 17.59 | 5.49 | -12.1 |
| Naming/MemoizedInstanceVariableName | 1.04 | 1.04 | 0.0 |
| Naming/RescuedExceptionsVariableName | 2.0 | 2.0 | 0.0 |
| Style/DisableCopsWithinSourceCodeDirective | 1.46 | 0.0 | -1.46 |
| Style/StringLiteralsInInterpolation | 1.04 | 1.04 | 0.0 |

## hashira: offenses per kLOC by cop

| Cop | Before | After | Delta |
| --- | --- | --- | --- |
| Kata/ClockDiscipline | 0.0 | 0.25 | 0.25 |
| Kata/RealWords | 0.0 | 0.5 | 0.5 |

## kimera: offenses per kLOC by cop

| Cop | Before | After | Delta |
| --- | --- | --- | --- |
| Kata/ClockDiscipline | 0.0 | 0.66 | 0.66 |
| Kata/RealWords | 0.0 | 3.72 | 3.72 |

## hashira: offenses this change adds and removes

| Cop | Added | Removed |
| --- | --- | --- |
| Kata/ClockDiscipline | 2 | 0 |
| Kata/RealWords | 4 | 0 |
| Metrics/AbcSize | 1 | 0 |

## kimera: offenses this change adds and removes

| Cop | Added | Removed |
| --- | --- | --- |
| Kata/ClockDiscipline | 8 | 0 |
| Kata/RealWords | 45 | 0 |
| Layout/BlockAlignment | 4 | 0 |
| Metrics/AbcSize | 1 | 0 |
