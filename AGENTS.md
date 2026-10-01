Mutation testing: before running kimera or triaging its results, read `bundle exec kimera skill`.

Design metrics: `bundle exec hashira --ratchet` gates CI against `hashira_baseline.json`. Fix what it reports; a deliberate exception goes under `accepted` with a reason naming why the code cannot change.
