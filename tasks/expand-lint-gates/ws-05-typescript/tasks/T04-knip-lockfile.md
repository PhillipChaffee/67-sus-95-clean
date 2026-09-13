# T04 (ts) knip + lockfile-lint (dependency hygiene)

Depends on: T01 · Touched: `knip.json` (new) and lockfile-lint config
(new, folder root), `typescript/ci.yml` + template copy,
`typescript/README.md`, templates, make sure that-sync list

## Steps

1. Pin knip from its docs. Configure entry points and project files for the
   template layout so it reports unused files, unused exports, and unused
   dependencies truthfully (validate on the example repo: a misconfigured
   knip flags everything or nothing).
2. Pin lockfile-lint. Configure the checks for package-lock.json (allowed
   hosts/schema, integrity). Every setting carries a reason.
3. Add `Dependency hygiene` and `Lockfile` CI jobs running the README
   commands.
4. README: commands, pins, remedies ("remove the dead export / fix the
   registry allowlist"), trade-offs.
5. Prove: clean pass. Seed an unused dependency and an unused export, and a
   bad-registry entry in a scratch lockfile. Make sure that failures. Record.
6. verify-sync.sh + repo lint. Commit.

## Acceptance criteria

Positive:

- [ ] knip exits 0 on the example repo with a correct entry config.
- [ ] Seeded unused dep / dead file / unused export each fail knip. Lockfile
      violation fails lockfile-lint.
- [ ] Configs carry reasons. Pins recorded.

Negative:

- [ ] knip config does not exclude src/ from its own report (never-imported
      sources must appear: mirror the vitest coverage.include lesson).
- [ ] No host allowlisted in lockfile-lint without a reason.
- [ ] make sure that-sync passes.
