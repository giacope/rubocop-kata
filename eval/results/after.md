# Scoreboard: 8e6d39f9a132

rubocop 1.92.0, rubocop-elegant 0.8.0, rubocop-kata 0.10.1

## Snippet cases (shipped defaults)

| Gap | Passed |
| --- | --- |
| R1 | 24 of 24 |
| R2 | 13 of 13 |
| R3 | 50 of 50 |
| R4 | 21 of 21 |
| R5 | 29 of 31 |
| R6 | 6 of 6 |
| R7 | 3 of 3 |
| R9 | 4 of 5 |
| R11 | 1 of 1 |
| extra | 13 of 13 |
| all | 164 of 167 |

## Still failing

- `job-subject-allowed`: expected no offense, found 1
- `job-doer-subject-flagged`: expected an offense, found none
- `disable-all-flagged`: expected an offense, found none

## -er/-or/-ar names (400 labels)

| Variant | Split | precision | recall | fp | fn | ambiguous_flagged | roles_flagged |
| --- | --- | --- | --- | --- | --- | --- | --- |
| raw | dev | 0.9928 | 0.965 | 1 | 5 | 10 | 17 |
| raw | holdout | 0.9841 | 0.8857 | 1 | 8 | 8 | 9 |
| raw | all | 0.9901 | 0.939 | 2 | 13 | 18 | 26 |
| shipped | dev | 0.9926 | 0.9441 | 1 | 8 | 8 | 14 |
| shipped | holdout | 1.0 | 0.8714 | 0 | 9 | 7 | 8 |
| shipped | all | 0.9949 | 0.9202 | 1 | 17 | 15 | 22 |

Raw rule on the dev split. False positives: Creditor. False negatives: Accumulator, Differ, Linter, Registrar, Requester.

## Shipped configuration

| Fact | Value |
| --- | --- |
| kata_cops | 19 |
| kata_cops_enabled | 18 |
| class_allowed_names | 9 |
| module_allowed_names | 9 |
| allowed_names_total | 18 |
| allowed_names_distinct | 9 |
| class_suffixes | 4 |
| banned_words | 0 |
| core_cops_silenced | 15 |
| layout_cops_silenced | 4 |
| no_comments_safe_autocorrect | false |
| no_comments_allow_documentation | true |
| inline_disable_banned | false |
| memoized_ivar_autocorrect | false |
| method_length_count_as_one | ["array", "hash", "heredoc", "method_call"] |
| abc_size_max | 17 |

## CLI

| Case | Result |
| --- | --- |
| plan-under-lang-c | pass |
| plan-stages-every-kata-cop | pass |
| doctor-reads-inherit-from | pass |
| doctor-reports-unparsable-file | pass |
| doctor-reports-undecodable-file | pass |
| doctor-lists-reasoned-disables | pass |
| doctor-clean-project | pass |
| plan-clean-project | pass |

## Corpora

| Corpus | Offenses | PerKLOC |
| --- | --- | --- |
| faraday | 1173 | 300.3 |
| rubygems.org | 7139 | 274.2 |
| hashira | 9 | 1.1 |
| kimera | 59 | 4.9 |

## Autocorrect safety

| Corpus | Mode | Unparsable | Comments kept | YARD kept | Encoding kept | Test failures |
| --- | --- | --- | --- | --- | --- | --- |
| faraday | -a | 0 | 1067/1068 | 257/257 | 0/0 | 0 |
| faraday | -A | 0 | 844/1068 | 257/257 | 0/0 | 0 |
| rubygems.org | -a | 0 | 1366/1370 | 12/12 | 0/0 | n/a |
| rubygems.org | -A | 0 | 755/1370 | 12/12 | 0/0 | n/a |

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
| Elegant/MonotonicIndents | 0.0 | 7.42 | 7.42 |
| Elegant/NoEmptyLinesInBlocks | 0.0 | 8.96 | 8.96 |
| Elegant/NoEmptyLinesInMethods | 0.0 | 26.63 | 26.63 |
| Elegant/NoNilReturn | 0.0 | 1.54 | 1.54 |
| Kata/ConstructorDiscipline | 0.0 | 12.29 | 12.29 |
| Kata/EnvDiscipline | 0.0 | 0.26 | 0.26 |
| Kata/GoodClassName | 0.0 | 1.79 | 1.79 |
| Kata/GoodMethodName | 0.0 | 27.91 | 27.91 |
| Kata/GoodModuleName | 0.0 | 1.28 | 1.28 |
| Kata/GoodVariableName | 0.0 | 20.23 | 20.23 |
| Kata/IoDiscipline | 0.0 | 0.51 | 0.51 |
| Kata/JustifiedDirective | 0.0 | 0.77 | 0.77 |
| Kata/NoClassMethodLogic | 0.0 | 5.12 | 5.12 |
| Kata/NoComments | 0.0 | 57.09 | 57.09 |
| Kata/NoHashAsObject | 0.0 | 0.51 | 0.51 |
| Kata/NoRedundantVariable | 0.0 | 3.33 | 3.33 |
| Kata/PairedBrackets | 0.0 | 6.14 | 6.14 |
| Kata/RealWords | 0.0 | 10.75 | 10.75 |
| Layout/ArgumentAlignment | 0.0 | 6.14 | 6.14 |
| Layout/LineEndStringConcatenationIndentation | 0.0 | 1.02 | 1.02 |
| Layout/MultilineAssignmentLayout | 0.0 | 7.68 | 7.68 |
| Layout/MultilineMethodCallIndentation | 0.0 | 0.77 | 0.77 |
| Layout/RedundantLineBreak | 0.0 | 2.56 | 2.56 |
| Metrics/AbcSize | 0.0 | 3.07 | 3.07 |
| Metrics/ClassLength | 0.0 | 1.02 | 1.02 |
| Metrics/MethodLength | 0.0 | 15.62 | 15.62 |
| Naming/BlockForwarding | 0.0 | 6.66 | 6.66 |
| Naming/MemoizedInstanceVariableName | 0.0 | 3.84 | 3.84 |
| Naming/PredicateMethod | 0.0 | 0.51 | 0.51 |
| Naming/RescuedExceptionsVariableName | 0.0 | 0.51 | 0.51 |
| Style/ArgumentsForwarding | 0.0 | 7.17 | 7.17 |
| Style/DocumentDynamicEvalDefinition | 0.0 | 0.77 | 0.77 |
| Style/ImplicitRuntimeError | 0.0 | 1.02 | 1.02 |
| Style/QuotedSymbols | 0.0 | 0.51 | 0.51 |
| Style/Send | 0.0 | 3.84 | 3.84 |
| Style/StringLiterals | 0.0 | 34.31 | 34.31 |
| Style/StringLiteralsInInterpolation | 0.0 | 1.02 | 1.02 |
| ThreadSafety/ClassAndModuleAttributes | 0.0 | 2.56 | 2.56 |
| ThreadSafety/ClassInstanceVariable | 0.0 | 4.1 | 4.1 |
| ThreadSafety/MethodRedefinition | 0.0 | 1.02 | 1.02 |

## rubygems.org: offenses per kLOC by cop

| Cop | Before | After | Delta |
| --- | --- | --- | --- |
| Elegant/MonotonicIndents | 0.0 | 6.76 | 6.76 |
| Elegant/NoEmptyLinesInBlocks | 0.0 | 12.02 | 12.02 |
| Elegant/NoEmptyLinesInMethods | 0.0 | 37.61 | 37.61 |
| Kata/BuilderNoun | 0.0 | 0.46 | 0.46 |
| Kata/ClassInModule | 0.0 | 0.88 | 0.88 |
| Kata/ClockDiscipline | 0.0 | 2.15 | 2.15 |
| Kata/ConstructorDiscipline | 0.0 | 4.03 | 4.03 |
| Kata/EnvDiscipline | 0.0 | 0.81 | 0.81 |
| Kata/GoodClassName | 0.0 | 6.91 | 6.91 |
| Kata/GoodMethodName | 0.0 | 49.67 | 49.67 |
| Kata/GoodModuleName | 0.0 | 0.88 | 0.88 |
| Kata/GoodVariableName | 0.0 | 23.05 | 23.05 |
| Kata/IoDiscipline | 0.0 | 1.27 | 1.27 |
| Kata/JustifiedDirective | 0.0 | 1.31 | 1.31 |
| Kata/NoBooleanFlag | 0.0 | 0.19 | 0.19 |
| Kata/NoClassMethodLogic | 0.0 | 7.03 | 7.03 |
| Kata/NoComments | 0.0 | 24.05 | 24.05 |
| Kata/NoHashAsObject | 0.0 | 1.58 | 1.58 |
| Kata/NoRedundantVariable | 0.0 | 4.46 | 4.46 |
| Kata/PairedBrackets | 0.0 | 7.61 | 7.61 |
| Kata/RealWords | 0.0 | 12.79 | 12.79 |
| Layout/ArgumentAlignment | 0.0 | 3.23 | 3.23 |
| Layout/ArrayAlignment | 0.0 | 1.15 | 1.15 |
| Layout/BlockAlignment | 0.0 | 0.81 | 0.81 |
| Layout/HashAlignment | 0.0 | 5.11 | 5.11 |
| Layout/LineEndStringConcatenationIndentation | 0.0 | 2.61 | 2.61 |
| Layout/LineLength | 0.0 | 7.64 | 7.64 |
| Layout/MultilineAssignmentLayout | 0.0 | 5.49 | 5.49 |
| Layout/RedundantLineBreak | 0.0 | 4.34 | 4.34 |
| Lint/RedundantCopDisableDirective | 0.0 | 0.54 | 0.54 |
| Lint/UselessConstantScoping | 0.0 | 1.19 | 1.19 |
| Metrics/AbcSize | 0.0 | 6.34 | 6.34 |
| Metrics/ClassLength | 0.0 | 1.04 | 1.04 |
| Metrics/MethodLength | 0.0 | 17.59 | 17.59 |
| Naming/MemoizedInstanceVariableName | 0.0 | 1.04 | 1.04 |
| Naming/RescuedExceptionsVariableName | 0.0 | 2.0 | 2.0 |
| Style/EmptyMethod | 0.0 | 0.5 | 0.5 |
| Style/FetchEnvVar | 0.0 | 0.58 | 0.58 |
| Style/FormatStringToken | 0.0 | 0.65 | 0.65 |
| Style/ImplicitRuntimeError | 0.0 | 0.54 | 0.54 |
| Style/Send | 0.0 | 0.65 | 0.65 |
| Style/StringLiteralsInInterpolation | 0.0 | 1.04 | 1.04 |
| ThreadSafety/ClassInstanceVariable | 0.0 | 0.54 | 0.54 |

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
