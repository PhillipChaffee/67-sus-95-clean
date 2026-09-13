# ws-05 spec: typescript gates

Status: planned · Starts after ws-01 · Parent: ../spec.md
Folder: `typescript/`

## Summary (product and user view)

TypeScript already has the tightest coverage gate (95% on four axes) and the
strictest tsc config (strict + eight beyond-strict flags). What it lacks is
the size/complexity family of core eslint rules, the SonarJS style metrics,
test-style linting, and the dependency tools (knip, dependency-cruiser,
lockfile-lint). This workstream adds them to `eslint.config.mjs` and CI, and
escalates unused-disable-directive reporting so suppressions cannot rot.

User view: a TS repo from this folder gains the same complexity/size/hygiene
gates the other languages get, with every threshold carrying a reason in the
config: matching the folder's "two tools must not argue about the same
byte" discipline.

Shared pattern:

1. Pin the tool or rule version from its official docs.
2. Add the rule to `eslint.config.mjs` with a reason for every choice.
3. `npm run lint` runs it.
4. Add the README section: command, pin, remedy, trade-offs.
5. Prove the gate both ways with a seeded violation.
6. Run verify-sync.sh. Commit.

## UX acceptance criteria

Positive:

- [ ] `npm run lint` fails with a clear rule name when a seeded violation is
      introduced (complexity, magic number, duplicate string, dead file,
      forbidden import, and commented-out code if the pinned sonarjs plugin
      ships that rule. Otherwise record the accepted gap per T02 and T08).
- [ ] The README lint list matches the eslint config exactly.
- [ ] knip and dependency-cruiser failures name the offending file/export.

Negative:

- [ ] No new rule enabled without a documented reason or threshold rationale.
- [ ] No rule fights prettier (the folder documents why stylistic rules are
      absent: new rules must keep that property).
- [ ] The coverage gate (95% × 4 axes) and the tsc flags are unchanged.

## Technical acceptance criteria

Positive:

- [ ] Core rules `complexity`, `max-lines`, `max-statements`,
`max-lines-per-function`, `max-depth`, `max-params` enabled with
      thresholds and reasons.
- [ ] `no-magic-numbers` and eslint-plugin-sonarjs (cognitive complexity,
      no-duplicate-string, commented-out code if the plugin ships it)
      enabled with a pinned plugin version.
- [ ] @vitest/eslint-plugin enabled (expect-expect + assertion style) with
      the vitest config-aware setup.
- [ ] knip wired for unused deps, dead files, unused exports (entry-point
      config for the template project).
- [ ] dependency-cruiser layer rules + cycle detection wired in CI.
- [ ] lockfile-lint gate on package-lock.json.
- [ ] `linterOptions.reportUnusedDisableDirectives: "error"` so
      suppressions cannot rot (match the eslint-docs option name at the
      pinned version).
- [ ] Templates byte-identical. verify-sync.sh passes.

Negative:

- [ ] No rule without a reason. No stylistic rule duplicating prettier.
- [ ] Suppression reporting not left at warn-only.
- [ ] No gate for a tool the audit found unworkable for TS (SAST stays a
      documented gap).

## Tasks (in order)

| task | gate |
| --- | --- |
| T01 | eslint core caps + suppression escalation |
| T02 | magic numbers + sonarjs (cognitive, duplicate strings, commented code) |
| T03 | vitest plugin (expect-expect, test style) |
| T04 | knip + lockfile-lint (dependency hygiene) |
| T05 | dependency-cruiser (layers + cycles) |
| T06 | mutation testing: StrykerJS (scheduled) |
| T07 | bidi / invisible-character gate (rg step) |
| T08 | document the accepted no-tool gaps |
