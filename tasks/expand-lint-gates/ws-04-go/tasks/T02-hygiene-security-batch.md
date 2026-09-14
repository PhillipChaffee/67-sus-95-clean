# T02 (go) batch: hygiene and security linters

Linters: godox, nolintlint, bidichk, gosec, depguard, gomodguard
Depends on: T01 · Touched: `go/.golangci.yml`, `go/README.md`,
templates, make sure that-sync list

## Steps

1. godox: enable with the policy from the uniform TODO decision (which
   markers, whether linked issues exempt). Record the policy in README.
2. nolintlint: require explanation and machine-readable format. No bare
   nolint. Make sure that settings keys against the pinned binary.
3. bidichk: default on (Trojan Source hygiene for go sources).
4. gosec: review the default check list. Enable, and disable only checks
   that fight the template's patterns, each with a reason.
5. depguard: define the layer rules for the template layout (small, obvious
   contract). Every package rule carries a reason.
6. gomodguard: configure blocked/replaced module policy (this is the go half
   of dependency bans).
7. README: extend the lint list per linter (reason, remedy, trade-offs).
8. Prove: seed violations (bare TODO, bare nolint, a bidi character, a
   gosec-flagged pattern, a forbidden import, a blocked module) and make sure that
   each fires. `golangci-lint config verify`. verify-sync.sh. Commit.

## Acceptance criteria

Positive:

- [ ] All six linters pass `config verify` and run clean (post-fixes) on the
      example project.
- [ ] Each seeded violation fails with output naming the linter and file.
- [ ] README lists each with reason + remedy.

Negative:

- [ ] No gosec check disabled without a reason.
- [ ] depguard rules cover the template's real packages.
  - Match the depguard package list against the module layout. The seeded
    forbidden import comes from a listed package.
- [ ] nolintlint does not permit bare nolint comments.
- [ ] Existing linters unchanged. Make sure that-sync passes.
