# T03 gate: gitleaks secret scan (all languages)

Depends on: none · Touched: `.gitleaks.toml` (new, repo root), all
four ci.yml templates + copies, folder READMEs, `scripts/verify-sync.sh`

## Steps

1. Pin gitleaks from its official docs. Use its default rule set.
2. Write the config: default rules on. Allowlist only for documented fixture
   files (test fixtures that fake credentials on purpose). Every allowlist
   entry gets a reason.
3. Add a `Secret scan` job to all four ci.yml templates + template copies,
   and to the repo's own hygiene workflow. The job runs the gitleaks command
   from the README (scan the full history in CI, not just the diff, so an
   already-committed secret is caught).
4. README section per folder: command, pin, remedy ("rotate the secret, purge
   it from history, allowlist only fixtures with a reason"), trade-offs.
5. Prove: clean run passes. A planted fake token fails. Record outputs.
6. verify-sync.sh + repo lint. Commit.

## Acceptance criteria

Positive:

- [ ] Scan exits 0 on the repo as-is.
- [ ] Seeded fake token fails the scan. Output names the file and line.
- [ ] Allowlist entries all carry reasons.

Negative:

- [ ] Gate does not scan only the diff in CI (history scan stays on).
- [ ] No fixture allowlisted without a reason.
- [ ] The gate is not warn-only, and verify-sync.sh passes.
