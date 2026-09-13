# T05 (ws-06) local parallel gate runner

Depends on: ws-01 through ws-05 (the runner wraps their gates)
Touched: run-gates.sh (new) in each of the four language folders, folder
READMEs (Commands section), template copies, `scripts/verify-sync.sh` list,
init skill gate lists if they enumerate commands

## Steps

1. Write run-gates.sh for each language folder. The script reads its gate
   list from the folder README commands (one source of truth), runs the
   PR-blocking gates in parallel (background jobs with a -j cap, or
   xargs -P), prints one pass or fail line per gate with the gate name, and
   exits nonzero when any gate fails.
2. Leave the mutation job out of the runner. Print one line that says the
   mutation gate runs on a schedule, so nobody reads its absence as a miss.
3. Add the runner to each folder README Commands section as the first
   command: run everything locally with ./run-gates.sh.
4. CI parity: match the runner gate list against the folder ci.yml job list
   with a grep. Every PR-blocking CI job must have a runner entry, and the
   reverse. Record the diff check in the README.
5. Record each gate's measured wall time on the template project in the
   folder README. The gate tasks record theirs too, so keep one table.
6. Sync templates, run verify-sync.sh and the repo lint steps. Commit.

## Acceptance criteria

Positive:

- [ ] ./run-gates.sh in a scratch repo initialized from the folder runs all
      PR-blocking gates and prints one line per gate.
- [ ] The runner exits nonzero when a seeded violation fails any gate.
- [ ] The runner gate list matches the ci.yml job list. The diff check is
      recorded in the README.
- [ ] Measured wall times per gate are recorded in the folder README.

Negative:

- [ ] The runner does not run the nightly mutation job.
- [ ] No PR-blocking gate in CI is missing from the runner, and the reverse.
- [ ] verify-sync.sh passes.
