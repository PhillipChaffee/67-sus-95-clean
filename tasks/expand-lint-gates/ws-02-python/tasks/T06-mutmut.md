# T06 (python) mutation testing: mutmut (scheduled job)

Depends on: T02 (tests and coverage layout exist) · Touched: mutmut
config (new), a scheduled workflow (new: see steps), `python/README.md`,
templates, `scripts/verify-sync.sh`

## Steps

1. Pin mutmut from its official docs. Mutation testing is too slow for PR
   CI: this gate runs as a scheduled (nightly) job, separate from the PR
   gates. Record that decision in the README.
2. Configure paths to mutate (the template's src package, not tests).
3. Choose a mutation-score floor (strict-but-usable. Record the reason and
   the measurement from a first run on the template project).
4. Add the scheduled workflow job. It fails when the score is below the
   floor. Failures are visible in the scheduled run, not PR runs.
5. README section: command, pin, floor and reason, remedy ("add a test that
   kills the surviving mutant"), trade-offs (runtime cost. Why nightly).
6. Prove: clean run at/above the floor passes. Seed a surviving mutant (add
   a function with no test) and make sure that the score drops below the floor.
   Record both outputs.
7. verify-sync.sh + repo lint. Commit.

## Acceptance criteria

Positive:

- [ ] A scheduled workflow exists with a cron schedule and the mutmut
      command from the README.
- [ ] Score at/above floor passes. Seeded surviving mutant fails.
- [ ] Floor and reason recorded in the README.

Negative:

- [ ] The mutation job is not on the PR path (only scheduled), per the
      documented decision.
- [ ] No threshold without a reason. verify-sync.sh passes.
