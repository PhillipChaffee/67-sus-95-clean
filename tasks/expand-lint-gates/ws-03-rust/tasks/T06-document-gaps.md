# T06 (rust) document the accepted no-tool gaps

Depends on: T01–T05 · Touched: `rust/README.md` trade-offs section,
`../../notes/gap-inventory.md` (rust section), init skill gate list if needed

## Steps

1. Write the accepted-gap list into the README trade-offs section in the
   folder's style: cognitive complexity (clippy's cognitive_complexity is
   approximate, not a McCabe gate), nesting-depth caps, magic-number
   detection, repeated literal to constant, class-size caps, commented-out code
   detection, SAST, test-style linting, assertion-less test detection,
   import-layer contracts, dependency-graph cycles.
2. One sentence each: what the missing signal is, why the current stack
   cannot see it, what changes the answer.
3. Point at the epic refusal note for the refused families.
4. Update the init skill gate list if it enumerates gates.
5. verify-sync.sh + repo lint. Commit.

## Acceptance criteria

Positive:

- [ ] Each accepted gap is listed with a reason in the README.
- [ ] The epic gap inventory matches the README list.

Negative:

- [ ] No gap described as enforced.
- [ ] No roadmap promises: gaps are current facts.
