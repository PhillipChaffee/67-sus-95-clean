# T01 gate: typos spell check (all languages)

Depends on: none · Touched: `.typos.toml` (new, repo root), all four
`<lang>/ci.yml` + their template copies, all four folder
READMEs, root README, `scripts/verify-sync.sh`

## Steps

1. Research the `typos` tool from its official docs. Pick and pin a version.
2. Write `.typos.toml` at the repo root. Add the default hard-coded
   corrections and the false-positive allowlist. Every entry gets a reason.
3. Add a `Spell check` job to all four ci.yml templates (and their
   byte-identical template copies). Job command: the `typos` check command
   from the README.
4. Add the README section per folder: what it checks, the pinned version, the
   command, the remedy ("fix the spelling or extend the allowlist with a
   reason"), and the trade-off note.
5. Prove the gate: clean run passes. Add a misspelled word to a fixture file,
   run again, it fails. Record both outputs in the README.
6. Run scripts/verify-sync.sh and the repo lint steps. Commit.

## Acceptance criteria

Positive:

- [ ] `typos` exits 0 on the repo as-is.
- [ ] Proof of failure recorded in each folder README (exit code nonzero on
      the seeded typo).
- [ ] Config entries all carry reasons. Tool version pinned in READMEs.

Negative:

- [ ] No allowlist entry without a reason.
- [ ] Gate is not warn-only (nonzero exit on violation).
- [ ] verify-sync.sh does not fail on template drift.
