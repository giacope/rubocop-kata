Mutation testing: before running kimera or triaging its results, read `bundle exec kimera skill`. The full run (`bundle exec kimera run`) keeps 0 survivors, 0 uncovered and nothing ignored; an equivalent mutant is a design problem to fix in the code.

Design metrics: `bundle exec hashira` reports 0 findings with no baseline, and CI fails on any finding. Fix what it reports; a finding that is a hashira misread goes to hashira as an issue, not into a baseline.

Lint: `bundle exec rubocop` runs kata bare on its own code (the `.rubocop.yml` holds only the plugin, the Ruby version and the excluded fixtures); a misread is fixed in kata, never configured around or disabled inline.
