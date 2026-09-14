# T07 (ts) gate: bidi / invisible-character hygiene (rg step)

Depends on: T05 (shares the CI file) · Touched:
`typescript/ci.yml` + template copy, `typescript/README.md`, templates,
`scripts/verify-sync.sh`

## Steps

1. Add a `Bidi hygiene` CI step: a ripgrep (or grep) check that fails on
   bidi and invisible control characters in source files (the Trojan Source
   attack vector). Use an explicit character-class pattern. Record the
   pattern and why each class is banned. Keep it a plain, auditable grep
   step: no new dependency needed.
2. README: the command, the character classes banned, the remedy ("rewrite
   the identifier/comment without the invisible characters"), trade-offs
   (legit non-ASCII text is fine. Only invisible/bidi control chars are
   banned: document the boundary).
3. Prove: clean pass. Seed a line containing a bidi control character in a
   fixture and make sure that it fails. Record outputs.
4. verify-sync.sh + repo lint. Commit.

## Acceptance criteria

Positive:

- [ ] The check exits 0 on the example repo as-is.
- [ ] A seeded bidi control character fails. Output names the file and line.
- [ ] The banned character classes are documented with reasons.

Negative:

- [ ] The pattern does not ban ordinary non-ASCII text (check: accented
      words and emoji in docs still pass).
- [ ] Gate is not warn-only. verify-sync.sh passes.
