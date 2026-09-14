# ws-06 spec: contracts, docs, and the final check

Status: planned · Starts after ws-01..ws-05 · Parent: ../spec.md

## Summary (product and user view)

The other workstreams add gates inside the language folders. This workstream
makes the repo itself tell the truth about the new baseline:

- The add-language skill's contract gains the new gate families, so the next
  language added to the repo carries hygiene and supply-chain gates from day
  one: not just lint/types/docs/coverage.
- The root README and the docs landing page show the expanded gate set per
  language.
- The rule mirrors (the new-repo-setup rule in ~/.agents and the harness
  copies) describe the fuller gate set.
- A final acceptance-criteria sweep walks every box in the epic spec against
  the finished work and records the result.

User view: someone adding a new language (say, Zig) gets a skill that
requires the same gate set as the existing folders. Someone reading the
README can see at a glance what every language enforces.

## UX acceptance criteria

Positive:

- [ ] add-language/SKILL.md requires the new gate families in its research
      and authoring steps.
  - Diff the skill file. Edits are additive only: existing headings and
    step text stay unchanged, and every new gate family appears in the
    research and authoring steps.
- [ ] The root README's language table shows the new gate columns/rows.
- [ ] docs/index.html lists the expanded table.
  - Grep docs/index.html for every new gate name (ws-06 T02 step 5). Save
    the rendered page under the epic notes as the fixture.
- [ ] The rule mirrors match the canonical rule text (a diff shows no drift).

Negative:

- [ ] No stale claim anywhere: no README, doc page, or skill claims a gate
      that a folder does not actually enforce (grep the tree).
- [ ] No mirror diverges from the canonical rule file.
- [ ] No refused metric appears as a requirement in add-language.

## Technical acceptance criteria

Positive:

- [ ] Every acceptance-criteria box in the epic spec and all workstream
      specs is checked, with the evidence recorded in
      notes/final-ac-check.md.
- [ ] add-language's validation section covers the new configs the same way
      it covers existing ones (parse every structured config. Prove gates
      fail).
- [ ] scripts/verify-sync.sh passes on the final tree.
- [ ] Each language folder ships run-gates.sh. It runs all PR-blocking gates
      in parallel, prints one summary line per gate, exits nonzero on any
      failure, and its gate list matches the ci.yml jobs.

Negative:

- [ ] No folder README claims enforcement that the epic's gap inventory
      marks as accepted-gap or refused.
- [ ] No workstream left an AC unchecked without a recorded reason.

## Tasks (in order)

| task | what |
| --- | --- |
| T01 | add-language skill contract update |
| T02 | root README + docs landing page |
| T03 | harness rule mirrors update |
| T03 | harness rule mirrors update |
| T04 | walk every acceptance criterion (epic-wide) |
| T05 | local parallel gate runner (run-gates.sh per folder) |
