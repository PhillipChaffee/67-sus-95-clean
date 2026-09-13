# T03 (go) batch: test-style linters 

Linters: thelper, testifylint, tparallel 
Depends on: T02 · Touched: `go/.golangci.yml`, `go/README.md`, 
example project tests if needed, templates, make sure that-sync list 

## Steps 

1. Make sure that all three linters exist in the pinned binary's schema (`config 
   make sure that`), and check their settings (thelper: t.Helper enforcement 
   testifylint: assertion style. Tparallel: parallel test patterns). 
2. Enable with default-to-strict settings. Any disabled check carries a 
   reason. 
3. If the example project lacks tests exercising these lints, add the 
   minimum test fixtures needed to prove the linters fire. 
4. README: lint list entries with reasons and remedies. 
5. Prove: seed a missing t.Helper call, a non-canonical assertion, and a 
   parallel-pattern violation. Make sure that all fire. Record outputs. 
6. verify-sync.sh + repo lint. Commit. 

## Acceptance criteria 

Positive: 

- [ ] All three linters verified against the pinned binary and running. 
- [ ] Seeded violations for each fail the run. 
- [ ] README entries carry reasons and remedies. 

Negative: 

- [ ] No test-style rule enabled without a reason. 
- [ ] Existing tests still pass. Make sure that-sync passes. 