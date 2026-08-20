---
name: rubocop-kata
description: >-
  Adopt rubocop-kata's rules on an existing codebase without the offense count going
  the wrong way. Kata's structural cops (ConstructorDiscipline, NoHashAsObject,
  Io/Clock/EnvDiscipline, NoClassMethodLogic, NoBooleanFlag) create names, and its naming
  cops (RealWords, GoodMethodName, GoodVariableName, AgentNoun, BuilderNoun, NoUtilName)
  charge for every name created — so a structural refactor removes offenses and adds more,
  and a single total cannot tell progress from regression. This skill sequences the work by
  stage, picks names that are already clean by checking them against the dictionary the cops
  read, and reports removed and created separately. Use when adopting rubocop-kata, working
  down a large kata backlog, deciding what to fix next, or when kata offenses went up after a
  refactor. Triggers on "rubocop-kata", "kata offenses", "kata offences", "kata backlog",
  "adopt kata".
---

# rubocop-kata adoption

> The count goes up mid-refactor because the refactor is doing its job. Stop reading the
> total; read the two numbers underneath it.

## The problem this solves

Move a collaborator out of a constructor and you satisfy `Kata/ConstructorDiscipline`. You
also mint a parameter, an ivar, and probably a reader — three names, each priced by
`Kata/RealWords`, `Kata/GoodVariableName`, and `Kata/BuilderNoun`. Net offenses can rise
while the code strictly improves. There is no configuration that fixes this, because the
names are real and someone has to choose them.

So choose them well the first time. Every name is checkable *before* it is written, against
the same dictionary the cops read. Do that and the naming debt is never created.

## Procedure

### 1. Clear dead configuration first

```
rubocop-kata doctor
```

It reports `.rubocop.yml` entries for cops the inherited config already disables, and
`rubocop:disable` comments naming a cop that is not enabled where the comment sits. RuboCop
reports neither. Delete what it names — it is free, and it stops you tuning knobs that are
not connected to anything.

### 2. Read the plan

```
rubocop-kata plan
```

It buckets every offense into four stages and names the one to work:

- **structure** — the cops that change the shape of the code, and in doing so mint names.
- **naming** — the cops that price names.
- **prose** — `NoComments`, `ProsePlacement`.
- **rest** — bundled and core cops; mostly mechanical, mostly autocorrectable.

Work the stage `plan` names, in that order. Structure before naming is the whole point: doing
naming first means renaming things the structural pass is about to move or delete.

### 3. Work one file at a time

Take the file `plan` calls densest. Fix its offenses for the **current stage only** — leave
the other stages' offenses alone even when they are on the line you are editing. Mixing
stages is what makes a diff unreviewable and a count unreadable.

For `rest`, prefer `rubocop -a` (safe corrections). Do not run `-A` (unsafe) across a
codebase; kata turns off the correctors known to rewrite code wrongly, but unsafe correctors
outside that list still change behaviour.

### 4. Check every name before you write it

This is the step that keeps the count honest. Kata's naming rules, condensed:

| rule | cop |
| --- | --- |
| one word, lowercase, ≤16 chars | `GoodMethodName`, `GoodVariableName` |
| a second word only via a role prefix (`after_fork`), a role suffix (`file_of`), or a reviewed `Terms` entry | same |
| never smash the underscore out — `errorcount` fails too | `RealWords` |
| every segment is a real word; no `cfg`, `ctx`, `msg`, `tmp`, … | `RealWords` |
| classes are not `-er`/`-or` doers | `AgentNoun` |
| no `Util`, `Helper`, `Manager`, `Service`, `Common`, `Shared` | `NoUtilName` |
| a method that returns something is named for what it returns, not `get_`/`calculate_`/`compute_` | `BuilderNoun` |
| memoization ivars are `@_name` | `Naming/MemoizedInstanceVariableName` |

Check a candidate against the shipped dictionary before committing to it:

```
ruby -rrubocop-kata -e 'puts ARGV.map { |w| "#{w}: #{RuboCop::Kata::Dictionary::ENTRIES.include?(w.downcase)}" }' clock sink cursor
```

If a word the domain genuinely needs is not in the dictionary, that is a `Terms` entry in
`.rubocop.yml`, not a reason to pick a worse name — but add it deliberately, one at a time,
and say why in the commit.

When a name is genuinely two words and neither the prefix nor the suffix list fits, that is
usually the cop telling you an object is missing. `evidence_poller` wants to be
`Evidence#poll` or an `EvidenceValidation`. Prefer extracting the object over adding a
`Terms` entry.

### 5. Re-run `plan` and report two numbers

```
rubocop-kata plan
```

Report the delta as **removed** and **created**, never as a net total:

> structure 184 → 142 (−42). naming 263 → 263 (+0 created, 21 names introduced, all clean).

A rising `naming` number after a structural pass means step 4 was skipped, not that the
refactor was wrong. Go back and fix the names you just wrote — it is cheaper now than after
they spread.

## Rules of engagement

- **Never `rubocop --auto-gen-config` to make a stage disappear.** A todo file converts a
  backlog you can see into one you cannot. If a cop is genuinely wrong for this codebase,
  turn it off in `.rubocop.yml` with a comment saying why; `doctor` will tell you later if
  that entry stops meaning anything.
- **Never widen `AllowedNames`/`Terms` in bulk.** One entry, one reviewed reason.
- **One stage per commit.** The reviewer needs to see a structural move as a structural move.
- **Stop and ask** when a fix requires a decision you cannot verify from the code: what a
  domain word means, whether a class is part of a public API, whether a framework resolves a
  class by its name. Guessing on those creates rework that lints clean.
