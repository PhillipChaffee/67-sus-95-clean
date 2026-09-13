# T05 (rust) mutation testing: cargo-mutants (scheduled job) 

Depends on: T02 (workspace layout) · Touched: cargo-mutants config 
(new, folder root), a scheduled workflow (new), `rust/README.md`, templates, 
`scripts/verify-sync.sh`

## Steps 

1. Pin cargo-mutants from its official docs. 
2. Choose a mutation-score floor (strict-but-usable. Record the reason). 
   Like the coverage gate, the floor must be provable both ways. 
3. Add a scheduled (nightly) workflow job running cargo-mutants with the 
   README command. Mutation testing is too slow for PR CI: record that 
   decision next to the gate, in the same style the coverage section uses. 
4. README section: command, pin, floor and reason, remedy ("add a test that 
   kills the mutant"), trade-offs. 
5. Prove: clean run at/above floor passes. A function with no test that 
   kills its mutants drops the score: make sure that it fails. Record outputs. 
6. verify-sync.sh + repo lint. Commit. 

## Acceptance criteria 

Positive: 

- [ ] Scheduled workflow exists with a cron schedule and the README command. 
- [ ] Score at/above floor passes. Seeded surviving mutant fails. 
- [ ] Floor and reason recorded in the README. 

Negative: 

- [ ] No mutation job on the PR path (scheduled only, per the decision). 
- [ ] No threshold without a reason. verify-sync.sh passes. 