# ws-03 spec: rust gates

Status: planned · Starts after ws-01 · Parent: ../spec.md
Folder: `rust/`

## Summary (product and user view)

Rust already has the strongest type and doc surface (clippy groups, rustdoc
deny, missing_docs, llvm-cov line gate). This workstream adds the
rust-specific gates that maintained tools support: cargo-deny (advisories,
licenses, dependency bans, duplicate versions), cargo-shear (unused
dependencies), a suppression-governance restriction pick, a uniform TODO
gate, and an investigation into tightening the coverage axes. What no tool
can check is written down as accepted gaps, not shipped as fake gates.

User view: a rust repo from this folder gets supply-chain enforcement and
stronger suppression hygiene without losing the "strict but staying usable"
balance the folder documents today.

Shared pattern:

1. Pin the tool from its official docs.
2. Write the config with a reason for every choice.
3. Add the CI job in `rust/ci.yml` and pair it with the byte-identical
   template copy.
4. Add the README section: command, pin, remedy, trade-offs.
5. Prove the gate both ways and record both outputs.
6. Run verify-sync.sh and the repo lint steps. Commit.

## UX acceptance criteria

Positive:

- [ ] `rust/ci.yml` has one labeled job per new gate.
- [ ] Each failure names the offending crate, file, or attribute.
- [ ] The rust README lists each new gate with its remedy and pin.

Negative:

- [ ] No new gate passes on a seeded violation.
- [ ] No restriction pick or deny added without a reason.
- [ ] Nothing here weakens the existing gates (clippy groups, rustdoc deny,
      the 95% line gate all still fire).

## Technical acceptance criteria

Positive:

- [ ] cargo-deny checks advisories, licenses, bans, and duplicate versions,
      with config entries that carry reasons.
- [ ] cargo-shear runs in CI against the workspace manifests.
- [ ] The restriction-picks table gains allow_attributes_without_reason with
      its reason, or a recorded refusal.
- [ ] A TODO gate exists (grep-based, per the uniform TODO policy) and has
      both-way proofs.
- [ ] Every new config has a byte-identical template copy. verify-sync.sh
      passes.

Negative:

- [ ] No warn-only gate.
- [ ] No gate added for a missing tool (cognitive complexity, nesting, magic
      numbers, repeated literals, class size, commented-out code, SAST stay
      documented gaps: see T06).
- [ ] The pinned toolchain (rust-toolchain.toml) is not changed as a side
      effect.

## Tasks (in order)

| task | gate |
| --- | --- |
| T01 | cargo-deny: advisories, licenses, bans, duplicates |
| T02 | cargo-shear: unused dependencies |
| T03 | suppression + TODO gates (allow_attributes_without_reason, grep gate) |
| T04 | coverage axes investigation (regions/branch on llvm-cov) |
| T05 | mutation testing: cargo-mutants (scheduled) |
| T06 | document the accepted no-tool gaps |
