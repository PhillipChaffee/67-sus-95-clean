# T01 (ts) eslint core caps + suppression escalation 

Rules: complexity, max-lines, max-statements, max-lines-per-function, 
max-depth, max-params + reportUnusedDisableDirectives escalation 
Depends on: none within ws-05 · Touched: 
`typescript/eslint.config.mjs`, `typescript/README.md`, template copies, 
`scripts/verify-sync.sh`

## Steps 

1. Make sure that the exact option shapes in the eslint docs at the pinned eslint 
   version (10.10.0 at planning time): each rule's option shape, and the 
   current name/location of the unused-disable-directives reporting option. 
2. Enable the six core rules with strict-but-usable thresholds (propose 
   justify each against the README trade-offs style: e.g. complexity max, 
   file/function line caps). Note: these rules are NOT in any tseslint 
   preset. They are explicit core entries. 
3. Escalate unused-disable-directive reporting from warn to error (per the 
   docs option name at this pin) so stale suppressions fail the build. 
4. Add one config comment per rule: threshold + why, and the overlap with other rules (for example max-lines against 
   max-lines-per-function). 
5. Run `npm run lint` on the example project. Fix or reason findings. 
6. README: lint list entries per rule with threshold, reason, remedy. 
7. Prove: seed violations for each family (a complex function, a long file, 
   deep nesting, too many params, a magic number: that one is T02: and a 
   stale disable directive). Record outputs. 
8. verify-sync.sh + repo lint. Commit. 

## Acceptance criteria 

Positive: 

- [ ] All six rules configured `npm run lint` passes on the example repo. 
- [ ] Seeded violations for each family fail with the rule name in output. 
- [ ] Stale `eslint-disable` directives fail the lint run. 
- [ ] Thresholds + reasons recorded in config and README. 

Negative: 

- [ ] No threshold without a justification. 
- [ ] No rule duplicates prettier's job. 
- [ ] Suppression reporting is not warn-only anymore. make sure that-sync passes. 