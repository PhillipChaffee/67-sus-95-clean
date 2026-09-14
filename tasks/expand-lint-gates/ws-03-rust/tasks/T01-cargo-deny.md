# T01 (rust) gate: cargo-deny (advisories, licenses, bans, duplicates)

Depends on: none within ws-03 · Touched: `deny.toml` (new, folder
root), `rust/ci.yml` + template copy, `rust/README.md`,
`rust/init-rust-repo/templates/`, `scripts/verify-sync.sh`

## Steps

1. Pin cargo-deny from its official docs. Record the install command.
2. Write `deny.toml`: advisories section (vulnerabilities fail), licenses
   section (allow-list with reasons), bans section (banned crates and
   duplicate-version rules with reasons), sources section if used. Every
   entry carries a reason.
3. Add `Dependency advisories`, `License check`, and `Dependency bans` jobs
   (or one job that reports per-section, so failures name the gate) to the
   rust ci.yml + template copy.
4. README section: the command, pin, remedy ("bump or replace. Ignore an
   advisory only with a reason and a date"), trade-offs.
5. Prove: clean run passes. Seed a known-vulnerable pin or a denied license
   in a scratch manifest, make sure that it fails. Record both outputs.
6. verify-sync.sh + repo lint. Commit.

## Acceptance criteria

Positive:

- [ ] cargo-deny exits 0 on the folder's example project.
- [ ] A seeded advisory (or denied license / banned crate) fails. Output
      names it.
- [ ] All config entries carry reasons. Pin recorded in README.

Negative:

- [ ] Advisories do not fail-open.
  - Record the mode. Run cargo-deny with the advisory DB unreachable and
    record a nonzero exit (fail-closed), or quote the documented failure
    mode in the README.
- [ ] No license allowed or banned without a reason.
- [ ] verify-sync.sh passes.
