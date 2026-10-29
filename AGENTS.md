Mutation testing: before running kimera or triaging its results, read `bundle exec kimera skill`. The full run (`bundle exec kimera run`) keeps 0 survivors, 0 uncovered and nothing ignored; an equivalent mutant is a design problem to fix in the code.

Design metrics: `bundle exec hashira` (strict) reports 0 findings, and CI fails on any finding. Fix what it reports; a finding that is a hashira misread goes to hashira as an issue, not into a baseline. The baseline accepts one finding by design, with its reason: Safeguard, prepended into RuboCop::Runner.

Lint: `bundle exec rubocop` runs kata on its own code with its strict profile (the `.rubocop.yml` holds the plugin, config/strict.yml, the Ruby version, the excluded fixtures, the upstream cop classes kata's own cops extend, and the files that prepend fixes into RuboCop's classes, which Kata/NoMonkeyPatch cannot pass); a misread is fixed in kata, never configured around or disabled inline.
