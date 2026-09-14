# T05 (ts) dependency-cruiser (layers + cycles)

Depends on: T01 · Touched: `.dependency-cruiser.cjs` (new, folder
root), `typescript/ci.yml` + template copy,
`typescript/README.md`, templates, make sure that-sync list

## Steps

1. Pin dependency-cruiser from its official docs.
2. Write the rules: forbidden imports between named layers (a small, obvious
   contract for the template layout) and the orphan/cycle checks. Every rule
   carries a reason.
3. Add a `Dependency graph` CI job running the README command (depcruise
   validate).
4. README section: command, pin, remedy, trade-offs.
5. Prove: clean pass. Seed a forbidden import and a module cycle in the
   example repo, make sure that they fail. Record outputs.
6. verify-sync.sh + repo lint. Commit.

## Acceptance criteria

Positive:

- [ ] depcruise validate exits 0 on the example repo.
- [ ] A seeded forbidden import and a seeded cycle each fail. Output names
      the modules.
- [ ] Rules carry reasons. Pin recorded.

Negative:

- [ ] Rules cover the template's real modules.
  - The seeded forbidden import and the seeded cycle sit under covered
    paths. depcruise validate fails and names the modules.
- [ ] make sure that-sync passes.
