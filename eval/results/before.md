# Scoreboard: 719080f4201c

rubocop 1.92.0, rubocop-elegant 0.8.0, rubocop-kata 0.10.1

## Snippet cases (shipped defaults)

| Gap | Passed |
| --- | --- |
| R1 | 5 of 24 |
| R2 | 5 of 13 |
| R3 | 35 of 50 |
| R4 | 8 of 21 |
| R5 | 13 of 31 |
| R6 | 3 of 6 |
| R7 | 0 of 3 |
| R9 | 1 of 5 |
| R11 | 0 of 1 |
| extra | 13 of 13 |
| all | 83 of 167 |

## Still failing

- `emacs-coding-kept`: expected no offense, found 1; correction removed "# -*- coding: binary -*-"
- `emacs-mode-line-kept`: expected no offense, found 1
- `vim-modeline-kept`: expected no offense, found 1; correction removed "# vim: set fileencoding=ascii-8bit :"
- `steep-type-kept`: expected no offense, found 1
- `rbs-inline-kept`: expected no offense, found 2
- `standard-directive-kept`: expected no offense, found 2
- `language-injection-kept`: expected no offense, found 1
- `noinspection-kept`: expected no offense, found 1
- `kimera-directive-kept`: expected no offense, found 1; correction removed "  # kimera:disable-next-line: IO.pipe write ends are sync; the flush is redundant"
- `hashira-directive-kept`: expected no offense, found 1
- `reek-directive-kept`: expected no offense, found 1
- `url-citation-kept`: expected no offense, found 2; correction removed "  # Net::HTTP reuses a socket the server already closed."; correction removed "  # See https://github.com/ruby/net-http/issues/42"
- `repo-issue-citation-kept`: expected no offense, found 1
- `bare-issue-citation-kept`: expected no offense, found 1
- `rfc-citation-kept`: expected no offense, found 1
- `cve-citation-kept`: expected no offense, found 1
- `yard-block-kept-by-default`: expected no offense, found 3; correction removed "# Sums the billable lines."; correction removed "# @return [Integer]"
- `yard-tag-lines-kept-by-default`: expected no offense, found 2
- `prose-survives-safe-autocorrect`: correction removed "  # add up the lines"
- `header-is-a-thing`: expected no offense, found 1
- `number-is-a-thing`: expected no offense, found 1
- `layer-is-a-thing`: expected no offense, found 1
- `letter-is-a-thing`: expected no offense, found 1
- `corner-is-a-thing`: expected no offense, found 1
- `matter-is-a-thing`: expected no offense, found 1
- `paper-is-a-thing`: expected no offense, found 1
- `header-module-is-a-thing`: expected no offense, found 1
- `clipping-flagged-args`: expected an offense, found none
- `clipping-flagged-opts`: expected an offense, found none
- `clipping-flagged-src`: expected an offense, found none
- `clipping-flagged-cmd`: expected an offense, found none
- `clipping-flagged-impl`: expected an offense, found none
- `clipping-flagged-util`: expected an offense, found none
- `clipping-flagged-calc`: expected an offense, found none
- `clipping-flagged-func`: expected an offense, found none
- `clipping-flagged-msgs`: expected an offense, found none
- `clipping-flagged-attrs`: expected an offense, found none
- `clipping-flagged-init`: expected an offense, found none
- `placeholder-flagged-foo`: expected an offense, found none
- `placeholder-flagged-baz`: expected an offense, found none
- `placeholder-flagged-qux`: expected an offense, found none
- `conversion-protocol-allowed`: expected no offense, found 1
- `attr-reader-two-words-flagged`: expected an offense, found none
- `attr-accessor-two-words-flagged`: expected an offense, found none
- `attr-writer-two-words-flagged`: expected an offense, found none
- `define-method-two-words-flagged`: expected an offense, found none
- `alias-method-two-words-flagged`: expected an offense, found none
- `alias-keyword-two-words-flagged`: expected an offense, found none
- `attr-reader-abbreviation-flagged`: expected an offense, found none
- `clock-keyword-seam-allowed`: expected no offense, found 1
- `clock-positional-seam-allowed`: expected no offense, found 1
- `clock-zone-now-flagged`: expected an offense, found none
- `clock-zone-today-flagged`: expected an offense, found none
- `clock-time-new-flagged`: expected an offense, found none
- `clock-monotonic-flagged`: expected an offense, found none
- `constructor-mutex-allowed`: expected no offense, found 1
- `constructor-kernel-conversion-allowed`: expected no offense, found 2
- `constructor-to-conversion-allowed`: expected no offense, found 2
- `constructor-defensive-copy-allowed`: expected no offense, found 1
- `constructor-empty-collection-allowed`: expected no offense, found 2
- `class-load-dump-coder-allowed`: expected no offense, found 2
- `class-json-create-allowed`: expected no offense, found 1
- `hash-to-h-allowed`: expected no offense, found 1
- `hash-as-json-allowed`: expected no offense, found 1
- `hash-deconstruct-keys-allowed`: expected no offense, found 1
- `boolean-exit-status-allowed`: expected no offense, found 1
- `boolean-exit-bang-allowed`: expected no offense, found 1
- `crowded-controller-subject-flagged`: expected an offense, found none
- `job-doer-subject-flagged`: expected an offense, found none
- `task-contract-allowed`: expected no offense, found 1
- `inherited-framework-name-allowed`: expected no offense, found 1
- `stdlib-subclass-allowed`: expected no offense, found 1
- `presenter-without-contract-flagged`: expected an offense, found none
- `nested-module-accepted-by-no-class-in-module`: expected no offense, found 1
- `zeitwerk-model-root-accepted`: expected no offense, found 1
- `zeitwerk-concern-root-accepted`: expected no offense, found 1
- `nested-call-corrected-with-indent`: correction produced "# frozen_string_literal: true\n\nVALUE = total(\n  lines(\n  1\n)\n)\n"
- `block-parameters-belong-to-the-brace`: expected no offense, found 1
- `hash-argument-corrected-with-indent`: correction produced "# frozen_string_literal: true\n\nVALUE = merge(\n  {\n  a: 1\n}\n)\n"
- `reasoned-disable-allowed-by-style`: expected no offense, found 2
- `bare-disable-flagged`: expected an offense, found none
- `trailing-bare-disable-flagged`: expected an offense, found none
- `disable-all-flagged`: expected an offense, found none
- `memoized-ivar-not-renamed`: correction removed "    @connection ||= open"
- `plan-under-lang-c`: stdout lacks /next: /; stderr has /Error/; stderr has /\.rb:\d+:in /
- `plan-stages-every-kata-cop`: stdout has /^rest .*Kata//
- `doctor-reads-inherit-from`: exit status 0, expected [1]; stdout lacks /\.rubocop_todo\.yml:1: `Elegant/GoodMethodName`/
- `doctor-reports-unparsable-file`: exit status 0, expected [1]; stdout lacks /broken\.rb/
- `doctor-reports-undecodable-file`: exit status 0, expected [1]; stdout lacks /binary\.rb/
- `doctor-lists-reasoned-disables`: stdout lacks /Avo resolves the handler by this name/

## -er/-or/-ar names (400 labels)

| Variant | Split | precision | recall | fp | fn | ambiguous_flagged | roles_flagged |
| --- | --- | --- | --- | --- | --- | --- | --- |
| raw | dev | 0.7447 | 0.979 | 48 | 3 | 13 | 15 |
| raw | holdout | 0.7753 | 0.9857 | 20 | 1 | 11 | 9 |
| raw | all | 0.7545 | 0.9812 | 68 | 4 | 24 | 24 |
| shipped | dev | 0.7665 | 0.8951 | 39 | 15 | 11 | 12 |
| shipped | holdout | 0.7625 | 0.8714 | 19 | 9 | 10 | 8 |
| shipped | all | 0.7652 | 0.8873 | 58 | 24 | 21 | 20 |

Raw rule on the dev split. False positives: Author, Banner, Barrier, Brother, Butter, Center, Charter, Color, Copper, Creditor, Cursor, Customer, Debtor, Dinner, Donor, Door, Error, Floor, Flower, Folder, Footer, Hammer, Honor, Humor, Ladder, Layer, Ledger, Manner, Matter, Meter, Minor, Number, Offer, Order, Power, Razor, Rigor, River, Rubber, Rumor, Sector, Shoulder, Shower, Summer, Tower, Trigger, Tumor, Tutor. False negatives: Beggar, Liar, Registrar.

## Shipped configuration

| Fact | Value |
| --- | --- |
| kata_cops | 18 |
| kata_cops_enabled | 17 |
| class_allowed_names | 45 |
| module_allowed_names | 45 |
| allowed_names_total | 90 |
| allowed_names_distinct | 45 |
| class_suffixes | 4 |
| banned_words | 16 |
| core_cops_silenced | 25 |
| layout_cops_silenced | 14 |
| no_comments_safe_autocorrect | true |
| no_comments_allow_documentation | false |
| inline_disable_banned | true |
| memoized_ivar_autocorrect | true |
| method_length_count_as_one | ["array", "hash", "heredoc", "method_call"] |
| abc_size_max | 50 |

## CLI

| Case | Result |
| --- | --- |
| plan-under-lang-c | fail |
| plan-stages-every-kata-cop | fail |
| doctor-reads-inherit-from | fail |
| doctor-reports-unparsable-file | fail |
| doctor-reports-undecodable-file | fail |
| doctor-lists-reasoned-disables | fail |
| doctor-clean-project | pass |
| plan-clean-project | pass |

## Corpora

| Corpus | Offenses | PerKLOC |
| --- | --- | --- |
| faraday | 1958 | 501.3 |
| rubygems.org | 7159 | 275.0 |
| hashira | 2 | 0.3 |
| kimera | 0 | 0.0 |

## Autocorrect safety

| Corpus | Mode | Unparsable | Comments kept | YARD kept | Encoding kept | Test failures |
| --- | --- | --- | --- | --- | --- | --- |
| faraday | -a | 0 | 61/1068 | 28/257 | 0/0 | 0 |
| faraday | -A | 0 | 61/1068 | 28/257 | 0/0 | 25 |
| rubygems.org | -a | 0 | 557/1370 | 0/12 | 0/0 | n/a |
| rubygems.org | -A | 0 | 558/1370 | 0/12 | 0/0 | n/a |

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
| Elegant/NoClassInModule | 0.0 | 9.22 | 9.22 |
| Elegant/NoEmptyLinesInBlocks | 0.0 | 8.96 | 8.96 |
| Elegant/NoEmptyLinesInMethods | 0.0 | 26.63 | 26.63 |
| Elegant/NoNilReturn | 0.0 | 1.54 | 1.54 |
| Kata/ConstructorDiscipline | 0.0 | 13.57 | 13.57 |
| Kata/EnvDiscipline | 0.0 | 0.26 | 0.26 |
| Kata/GoodClassName | 0.0 | 1.02 | 1.02 |
| Kata/GoodMethodName | 0.0 | 25.09 | 25.09 |
| Kata/GoodModuleName | 0.0 | 1.28 | 1.28 |
| Kata/GoodVariableName | 0.0 | 20.23 | 20.23 |
| Kata/IoDiscipline | 0.0 | 0.51 | 0.51 |
| Kata/NoClassMethodLogic | 0.0 | 5.38 | 5.38 |
| Kata/NoComments | 0.0 | 256.78 | 256.78 |
| Kata/NoHashAsObject | 0.0 | 0.77 | 0.77 |
| Kata/NoRedundantVariable | 0.0 | 3.33 | 3.33 |
| Kata/PairedBrackets | 0.0 | 6.14 | 6.14 |
| Kata/RealWords | 0.0 | 8.19 | 8.19 |
| Layout/ArgumentAlignment | 0.0 | 6.14 | 6.14 |
| Layout/LineEndStringConcatenationIndentation | 0.0 | 1.02 | 1.02 |
| Layout/MultilineAssignmentLayout | 0.0 | 7.68 | 7.68 |
| Layout/RedundantLineBreak | 0.0 | 2.56 | 2.56 |
| Metrics/ClassLength | 0.0 | 1.02 | 1.02 |
| Metrics/MethodLength | 0.0 | 15.62 | 15.62 |
| Naming/BlockForwarding | 0.0 | 6.66 | 6.66 |
| Naming/MemoizedInstanceVariableName | 0.0 | 3.84 | 3.84 |
| Naming/PredicateMethod | 0.0 | 0.51 | 0.51 |
| Naming/RescuedExceptionsVariableName | 0.0 | 0.51 | 0.51 |
| Style/ArgumentsForwarding | 0.0 | 7.17 | 7.17 |
| Style/DisableCopsWithinSourceCodeDirective | 0.0 | 1.02 | 1.02 |
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
| Kata/ClassInModule | 0.0 | 5.57 | 5.57 |
| Kata/ClockDiscipline | 0.0 | 1.54 | 1.54 |
| Kata/ConstructorDiscipline | 0.0 | 4.3 | 4.3 |
| Kata/EnvDiscipline | 0.0 | 0.81 | 0.81 |
| Kata/GoodClassName | 0.0 | 5.8 | 5.8 |
| Kata/GoodMethodName | 0.0 | 48.98 | 48.98 |
| Kata/GoodModuleName | 0.0 | 0.81 | 0.81 |
| Kata/GoodVariableName | 0.0 | 23.05 | 23.05 |
| Kata/IoDiscipline | 0.0 | 1.27 | 1.27 |
| Kata/NoBooleanFlag | 0.0 | 0.19 | 0.19 |
| Kata/NoClassMethodLogic | 0.0 | 7.11 | 7.11 |
| Kata/NoComments | 0.0 | 30.5 | 30.5 |
| Kata/NoHashAsObject | 0.0 | 1.58 | 1.58 |
| Kata/NoRedundantVariable | 0.0 | 4.46 | 4.46 |
| Kata/PairedBrackets | 0.0 | 8.18 | 8.18 |
| Kata/RealWords | 0.0 | 10.41 | 10.41 |
| Layout/ArgumentAlignment | 0.0 | 3.23 | 3.23 |
| Layout/ArrayAlignment | 0.0 | 1.15 | 1.15 |
| Layout/HashAlignment | 0.0 | 5.11 | 5.11 |
| Layout/LineEndStringConcatenationIndentation | 0.0 | 2.61 | 2.61 |
| Layout/LineLength | 0.0 | 7.64 | 7.64 |
| Layout/MultilineAssignmentLayout | 0.0 | 5.49 | 5.49 |
| Layout/RedundantLineBreak | 0.0 | 4.34 | 4.34 |
| Lint/RedundantCopDisableDirective | 0.0 | 0.61 | 0.61 |
| Lint/UselessConstantScoping | 0.0 | 1.19 | 1.19 |
| Metrics/ClassLength | 0.0 | 1.04 | 1.04 |
| Metrics/MethodLength | 0.0 | 17.59 | 17.59 |
| Naming/MemoizedInstanceVariableName | 0.0 | 1.04 | 1.04 |
| Naming/RescuedExceptionsVariableName | 0.0 | 2.0 | 2.0 |
| Style/DisableCopsWithinSourceCodeDirective | 0.0 | 1.46 | 1.46 |
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

## kimera: offenses per kLOC by cop

| Cop | Before | After | Delta |
| --- | --- | --- | --- |
