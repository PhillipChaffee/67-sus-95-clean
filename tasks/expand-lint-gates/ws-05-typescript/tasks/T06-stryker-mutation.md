# T06 (ts) mutation testing: StrykerJS (scheduled job) 

Depends on: T03 (test setup) · Touched: stryker config (new, folder 
root), a scheduled workflow (new), `typescript/README.md`, templates, 
`scripts/verify-sync.sh`

## Steps 

1. Pin @stryker-mutator/core (and the vitest runner plugin) from its 
   official docs, matched to the template's vitest pin. 
2. Configure mutators and a mutation-score floor (strict-but-usable. Reason 
   recorded). Mutation testing is too slow for PR CI: run it as a scheduled 
   (nightly) job. Record that decision. 
3. Add the scheduled workflow job running the README command. 
4. README section: command, pin, floor and reason, remedy ("add a test that 
   kills the surviving mutant"), trade-offs (runtime cost). 
5. Prove: clean run at/above floor passes. A function with no killing test 
   drops the score: make sure that it fails. Record both outputs. 
6. verify-sync.sh + repo lint. Commit. 

## Acceptance criteria 

Positive: 

- [ ] Scheduled workflow exists with a cron schedule and the README command. 
- [ ] Score at/above floor passes. Seeded surviving mutant fails. 
- [ ] Floor and reason recorded in the README. 

Negative: 

- [ ] No mutation job on the PR path (per the documented decision). 
- [ ] No threshold without a reason. verify-sync.sh passes. 