# T02 (ts) magic numbers + sonarjs plugin

Depends on: T01 (shares eslint.config.mjs) · Touched:
`typescript/eslint.config.mjs`, `typescript/package.json` (plugin pin),
`typescript/README.md`, templates, make sure that-sync list

## Steps

1. Enable core `no-magic-numbers` with a threshold and documented allowlist
   shape (the rule allows configuring exceptions: every allowance carries a
   reason).
2. Install and pin eslint-plugin-sonarjs. Make sure that its actual rule list at the
   pinned version: cognitive complexity, no-duplicate-string, and whether a
   commented-out-code rule exists. Only promise what the plugin ships: see
   the workstream note.
3. Enable the confirmed sonarjs rules with strict thresholds and reasons.
4. README: entries per rule with remedy. Note the S-id ↔ eslint rule mapping
   where it exists, and record any SonarQube rule the plugin does not ship
   as an accepted gap (T08 documents it).
5. Prove: seeded magic number, repeated string, and commented-out code (if
   supported) each fail. Clean run passes. Record outputs.
6. verify-sync.sh + repo lint. Commit.

## Acceptance criteria

Positive:

- [ ] `npm run lint` exits 0 on the example repo after fixes.
- [ ] Seeded magic number, repeated string, and (if shipped) commented-out
      code all fail with the rule name.
- [ ] Plugin version pinned. README states exactly which Sonar rules map.

Negative:

- [ ] No sonar rule claimed that the plugin does not ship (T08 re-checks).
- [ ] no-magic-numbers allowlist entries all carry reasons.
- [ ] make sure that-sync passes. Prettier conflict property preserved.
