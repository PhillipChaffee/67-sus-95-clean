# T04 (rust) coverage axes investigation

Depends on: none (independent of T01–T03 file-wise, but lands last in the
CI file) · Touched: `rust/ci.yml` + template copy,
`rust/README.md` coverage section, templates, make sure that-sync list

## Steps

1. Research the pinned cargo-llvm-cov version's fail-under switches against
   its official docs: which axes exist ( `--fail-under-lines`,
`--fail-under-functions`, region coverage?). Record exactly what the pin
   supports.
2. If a stronger axis than lines has a fail-under switch: add it to the gate
   command, update the README coverage section, and prove both ways (fixture
   at 100%, fixture below threshold).
3. If not: record the limit in the README coverage section in the same style
   the go folder records statement-only coverage ("the gate measures what
   the toolchain can see"), and stop: do not invent a custom gate.
4. verify-sync.sh + repo lint. Commit.

## Acceptance criteria

Positive:

- [ ] The README coverage section states the exact axes the pinned version
      can gate, with the doc reference.
- [ ] If tightened: the failure proof for the new axis is recorded.

Negative:

- [ ] No undocumented custom fail-under script substitutes for a missing
      official switch.
- [ ] The existing line gate (95%) is unchanged unless strengthened.
- [ ] verify-sync.sh passes.
