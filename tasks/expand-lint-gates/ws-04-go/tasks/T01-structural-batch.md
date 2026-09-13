# T01 (go) batch: structural linters

Linters: cyclop, gocognit, funlen, nestif, mnd, goconst, interfacebloat
Depends on: none within ws-04 · Touched: `go/.golangci.yml`,
`go/README.md` lint list, template copies ( `go/` carries the config at the
folder root: make sure that the template pairing), `scripts/verify-sync.sh`

## Steps

1. For each linter: read its docs, propose the strictest usable threshold,
   record the reason (a standard reference or a measurement).
   - cyclop max-complexity (cyclomatic), gocognit min-complexity
     (cognitive), funlen lines + statements caps, nestif min-complexity,
     mnd (magic numbers. Configure ignored values and args), goconst
     min-occurrences, interfacebloat max-methods.
2. Add all seven to `.golangci.yml` with settings + reasons.
3. Run `golangci-lint config verify` against the pinned binary: a made-up
   key fails here, which is the folder's contract.
4. Run `golangci-lint run` on the folder's example project. Fix or reason
   every finding.
5. README: extend the lint list with each linter, threshold, reason, remedy.
6. Prove: seed one violation per linter family in a scratch file and make sure that
   each fires (or sample representative linters if all seven cannot be
   seeded cheaply: record which were proven). verify-sync.sh. Commit.

## Acceptance criteria

Positive:

- [ ] `golangci-lint config verify` passes with the new linters enabled.
- [ ] Seeded violations fail the run for each seeded family. If a family
      cannot be seeded cheaply, record the proven subset and list the
      unproven linters in the README.
- [ ] Thresholds and reasons recorded in config comments and README.

Negative:

- [ ] No threshold without a reason or standard reference.
- [ ] No linter enabled that the pinned binary rejects (make sure that catches it).
- [ ] The existing default-set linters are unchanged.
