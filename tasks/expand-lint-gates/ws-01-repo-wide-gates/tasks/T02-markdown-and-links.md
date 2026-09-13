# T02 gates: markdown lint + link check (all languages)

Depends on: none · Touched: `.markdownlint-cli2.jsonc` and `lychee`
config (new, repo root), all four ci.yml + template copies, folder READMEs,
`scripts/verify-sync.sh`

## Steps

1. Pin markdownlint-cli2 and lychee versions from their official docs.
2. Write the markdownlint config with the chosen rule set. Strict but usable:
   start from the recommended set, disable only what fights the README style,
   each choice with a reason.
3. Write the lychee config: retry policy, exclusions (offline-only domains,
   example URLs in docs). Every exclusion carries a reason.
4. Add `Markdown lint` and `Link check` jobs to all four ci.yml templates +
   template copies. Add the root hygiene workflow jobs.
5. README sections per folder: command, pin, remedy, trade-offs (link check
   needs network. Document the retry and exclusion policy).
6. Prove both gates: clean pass. Seeded failure (a malformed markdown rule
   break and a dead link) fails. Record outputs.
7. verify-sync.sh + repo lint. Commit.

## Acceptance criteria

Positive:

- [ ] Both gates exit 0 on the repo as-is.
- [ ] Failure proofs recorded for both (nonzero exit on seeded violations).
- [ ] Configs parse. Every rule choice and exclusion carries a reason.

Negative:

- [ ] Link check does not pass on a dead link.
  - The lychee config records a retry count and a timeout. A seeded dead
    link fails with a nonzero exit after the retries. Excluded hosts appear
    in the config with a reason.
- [ ] No markdown rule disabled without a reason.
- [ ] verify-sync.sh passes.
