# Evaluation results

`before.json` is `main` at `719080f`, `after.json` is this branch at `8e6d39f`,
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
  line, this one included; `rubocop-kata doctor` lists it instead).
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
- **MethodLength by CountAsOne** answers whether folding wrapped calls hollows
  the metric: without the fold, 5 more faraday methods and 44 more
  rubygems.org methods fail, nearly all for layout alone; `Metrics/AbcSize` at
  17 catches the 15 methods whose logic the fold hid.


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
| extra | 13 → 13 of 13 |
| all | 83 → 164 of 167 |

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
| faraday | 1958 → 1173 | 501.3 → 300.3 |
| rubygems.org | 7159 → 7139 | 275.0 → 274.2 |
| hashira | 2 → 9 | 0.3 → 1.1 |
| kimera | 0 → 59 | 0.0 → 4.9 |

## Autocorrect safety

| Corpus | Mode | Unparsable | Comments kept | YARD kept | Encoding kept | Test failures |
| --- | --- | --- | --- | --- | --- | --- |
| faraday | -a | 0 → 0 | 61/1068 → 1067/1068 | 28/257 → 257/257 | 0/0 → 0/0 | 0 → 0 |
| faraday | -A | 0 → 0 | 61/1068 → 844/1068 | 28/257 → 257/257 | 0/0 → 0/0 | 25 → 0 |
| rubygems.org | -a | 0 → 0 | 557/1370 → 1366/1370 | 0/12 → 12/12 | 0/0 → 0/0 | n/a → n/a |
| rubygems.org | -A | 0 → 0 | 558/1370 → 755/1370 | 0/12 → 12/12 | 0/0 → 0/0 | n/a → n/a |

## Metrics/MethodLength offenses by CountAsOne

| Corpus | kata | without_method_call | none |
| --- | --- | --- | --- |
| faraday | 61 | 66 | 70 |
| rubygems.org | 458 | 502 | 569 |
| hashira | 0 | 0 | 0 |
| kimera | 0 | 6 | 13 |

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
| Kata/GoodMethodName | 25.09 | 27.91 | 2.82 |
| Kata/GoodModuleName | 1.28 | 1.28 | 0.0 |
| Kata/GoodVariableName | 20.23 | 20.23 | 0.0 |
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
| Metrics/MethodLength | 15.62 | 15.62 | 0.0 |
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
| Kata/GoodMethodName | 48.98 | 49.67 | 0.69 |
| Kata/GoodModuleName | 0.81 | 0.88 | 0.07 |
| Kata/GoodVariableName | 23.05 | 23.05 | 0.0 |
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
| Metrics/MethodLength | 17.59 | 17.59 | 0.0 |
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
| Kata/GoodMethodName | 0.0 | 0.08 | 0.08 |
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
| Kata/GoodMethodName | 1 | 0 |
| Kata/RealWords | 45 | 0 |
| Layout/BlockAlignment | 4 | 0 |
| Metrics/AbcSize | 1 | 0 |
