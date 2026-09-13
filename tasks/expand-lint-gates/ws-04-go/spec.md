# ws-04 spec: go gates 

Status: planned · Starts after ws-01 · Parent: ../spec.md 
Folder: `go/`

## Summary (product and user view) 

The go folder's linter is golangci-lint v2 with a pinned binary (v2.13.2 at 
planning time). This workstream enables, in three batches, the linters the 
audit identified as missing: structural caps, hygiene and security, and 
test-style checks. Every enable follows the folder's own contract: the 
linter name is verified against the pinned binary's schema (`golangci-lint 
config verify` rejects made-up keys), the threshold carries a reason, and 
the gate is proven both ways. 

User view: a go repo from this folder gets complexity, size, and hygiene 
gates from the same binary it already runs: no new toolchain, same pin. 

Shared pattern: 

1. Run `golangci-lint config verify` for every linter name against the pinned 
   binary. A made-up settings key fails there. 
2. Add the linters to `.golangci.yml` with reasons. 
3. CI already runs `golangci-lint run`. 
4. Add the README section per batch: threshold, reason, remedy. 
5. Prove the gate both ways with a seeded violation. 
6. Run verify-sync.sh. Commit. 

## UX acceptance criteria 

Positive: 

- [ ] Each batch's linters appear in `.golangci.yml` with thresholds and 
      reasons, and `golangci-lint config verify` passes. 
- [ ] Each gate failure names the function/file and the limit it crossed. 
- [ ] The go README lint list matches the config exactly (no linter in one 
      and not the other). 

Negative: 

- [ ] No linter enabled without a documented reason. 
- [ ] No threshold set without a why (or a standard reference). 
- [ ] `golangci-lint config verify` runs clean and rejects bad input. 
  - Make sure that config verify exits 0 on the final config, and that it 
    exits nonzero on a seeded made-up key. Record both outputs in the go 
    README. 

## Technical acceptance criteria 

Positive: 

- [ ] Batch linters: cyclop, gocognit, funlen, nestif, mnd, goconst, 
      interfacebloat, godox, nolintlint, bidichk, gosec, depguard, 
      gomodguard, thelper, testifylint, tparallel: each verified against 
      the pinned binary and given a threshold + reason (or a recorded 
      refusal with one). 
- [ ] A `go mod tidy -diff` CI step gates unused dependencies. 
- [ ] The `issues.max-issues-per-linter: 0` / `max-same-issues: 0` report 
      policy still holds (new linters never capped). 
- [ ] Every new config has a byte-identical template copy. verify-sync.sh 
      passes `golangci-lint config verify` recorded in the README. 

Negative: 

- [ ] No linter enabled that the pinned binary does not know (schema make sure that 
      is the check). 
- [ ] No gate is warn-only. 
- [ ] The coverage gate (statements ≥ 95%) is unchanged. 

## Tasks (in order) 

| task | batch | 
|---|---| 
| T01 | structural: cyclop, gocognit, funlen, nestif, mnd, goconst, interfacebloat | 
| T02 | hygiene/security: godox, nolintlint, bidichk, gosec, depguard, gomodguard | 
| T03 | test-style: thelper, testifylint, tparallel | 
| T04 | go mod tidy -diff gate | 
| T05 | dead-code investigation: x/tools deadcode | 
| T06 | document the accepted no-tool gaps | 