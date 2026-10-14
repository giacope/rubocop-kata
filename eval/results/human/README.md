# Human labels for the doer rule

The 400 labels in `eval/names.yml` were written by the author, and the
readability study behind the defaults was rated by AI reviewers. No human
has checked either. This kit asks one person to label a sample of the names
blind, then measures how far they agree with `eval/names.yml` and how the
raw doer rule scores against them.

## The sample

`names.yml` here holds 40 names: 16 that `eval/names.yml` calls doers, 16
things and 8 ambiguous, a third of each from the holdout (CRC32 divisible by
3), leaving out the ten names the rule below uses as examples. Each stratum
is ranked by SHA-256 of the salt `kata-human-1` and the name, its first names
are taken, and the file lists all 40 in that order, so labels do not cluster.
`eval/run --draw` rebuilds the file byte for byte:

```sh
eval/run --draw --out eval/results/human/names.yml
```

## The rule

The same rule `eval/names.yml` was labelled by:

- **doer**: the word's dominant sense is "one, or that, which <verb>s" for an
  English verb: Parser parses, Timer times, User uses. People are doers too
  (User, Buyer).
- **thing**: the dominant sense is not the agent of a verb: the ending is not
  the suffix (Number, Water, Corner), or the agent sense is rare or lost
  (Layer is a thickness before it is a hen; Header is a heading; Folder is
  the folded cover, the patient, not the agent).
- **ambiguous**: both readings are common in code.

A coinage (a name no dictionary has) counts as the doer its suffix says.

## Filling it in

1. Label alone and before looking at `eval/names.yml`, `eval/cases`, the cop
   or its `data/` files. A general dictionary is fine.
2. After each name's colon, write `doer`, `thing` or `ambiguous`:
   `Parser: doer`. Leave a name blank only if you skip it; blanks are not
   scored.
3. Fill this `names.yml` in place, or a copy for a second rater
   (`names.<initials>.yml`).

## Scoring it

```sh
eval/run --kata . --only human --out eval/results/human/score.json
eval/run --kata . --only human --labels eval/results/human/names.<initials>.yml --out ...
```

This writes `score.json` and `score.md`, and reports:

- **Agreement** with `eval/names.yml` over the three labels (its `roles` are
  doers), as a count and as Cohen's κ, which discounts the agreement two
  raters would reach by chance given how often each uses each label. Values
  above 0.6 are usually read as substantial agreement, above 0.8 as strong.
  Each disagreement is listed with both labels.
- **The raw doer rule** (`AllowedNames`, `Suffixes` and `Terms` cleared, as
  in `../README.md`) scored against the human's labels and, on the same
  names, against `eval/names.yml`: precision, recall, false positives and
  false negatives. Ambiguous names are scored apart, as they are there;
  `score.json` names each error.

Report the disagreements as they are; do not edit `eval/names.yml` to match.
