# typescript/ — the TypeScript strict baseline

The stack below is worked, not theoretical: every command in this folder
was run against a fresh repository initialized from the templates here —
`npm install` from the exact pins, then all five gates green (100% on all
four coverage axes) — and the coverage gate was proven to FAIL at 50%
branches. Pinned tool versions: typescript 6.0.3, eslint 10.10.0 +
typescript-eslint 8.70.0, eslint-plugin-jsdoc 64.3.8, vitest 5.0.0 +
@vitest/coverage-v8 5.0.0, prettier 3.9.6 (verified 2026-09, node 24).

## What is enforced

### Linting — eslint + typescript-eslint

`eslint.config.mjs` carries the flat config:

- `@eslint/js` `recommended` for every file format the repo carries,
  including the lint config itself.
- `tseslint.configs.strictTypeChecked` on TS sources — the strict preset
  WITH type information, driven by
  `parserOptions: { projectService: true }`, the documented shape from
  typescript-eslint's typed-linting guide. Typed rules are live in this
  stack, not decorative: the proof run showed
  `@typescript-eslint/no-floating-promises` reject a floating call.
- A hand-picked strict slice of `eslint-plugin-jsdoc` (see Documentation),
  and eslint core's two comment rules (see Comments).
- eslint core metric caps, explicit core entries (none is in any
  typescript-eslint preset), each with its threshold and reason in the
  config: `complexity` (max 10 — the McCabe reference point, parity with
  the go folder's cyclop and rust's size family), `max-lines` (300, blank
  lines and comments excluded — a file that does not fit a screen or two
  is two modules), `max-statements` (40 — parity with go's funlen
  statements cap), `max-lines-per-function` (60 with the same exclusions —
  the readable-screen rule; max-lines bounds the sum, this bounds each
  part), `max-depth` (4 — past that, extraction stops being optional), and
  `max-params` (3, the eslint documented default — a 4th positional
  parameter is an unnamed context object). All six proven both ways on the
  template fixture: a seeded violation per family fails with the rule name
  in the output.
- Stale suppressions fail the build: `linterOptions.reportUnusedDisableDirectives`
  is escalated from eslint's warn default to `error`, so an
  `eslint-disable` whose rule no longer fires is a build failure, not a
  suggestion. Proven: a seeded stale directive fails the lint run.
- Deliberately absent, with reasons: `spaced-comment` is deprecated in
  core (8.53.0, moved to @stylistic) and prettier owns comment whitespace
  in this stack; typescript-eslint's `stylistic` preset is opinion-heavy
  consistency rules prettier already normalizes — enabling it makes two
  tools argue about the same byte.

Warnings do not exist in this folder: everything enabled is reported at
`error`, so `eslint .` is a gate, not a suggestion box.

### Type checking — tsc

`tsconfig.json` turns on `strict: true` and, on top of it, the eight
beyond-strict flags (each with its ownership cost commented in place):
`noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`,
`noImplicitOverride`, `noFallthroughCasesInSwitch`, `noImplicitReturns`,
`noPropertyAccessFromIndexSignature`, `noUncheckedSideEffectImports`,
`verbatimModuleSyntax` — plus `noUnusedLocals`/`noUnusedParameters`.
`skipLibCheck` is on so dependency `.d.ts` files cannot fail the build;
the repo's own sources stay fully checked. The proof run also confirmed a
flag bites: reading `xs[0]` into arithmetic under `noUncheckedIndexedAccess`
is TS2532.

`module: "preserve"` + `moduleResolution: "bundler"`: module keywords stay
as written (pairs with `verbatimModuleSyntax`), resolution matches what
bundlers and vitest do.

typescript is pinned to 6.0.3 exactly: typescript-eslint documents support
for `>=4.8.4 <6.1.0`, and TypeScript 7 (the native rewrite) is outside that
window. Bumping is a deliberate change: raise the pin, run
`npm run typecheck && npm run lint`, fix what fell over in the same
commit — the rust folder's toolchain-bump policy, transposed.

### Documentation & comments — jsdoc rules + prose policy

Machine (the jsdoc strict slice):

- `require-jsdoc`: every exported function declaration, plus exported
  arrow-function and function-expression consts via two extra AST contexts —
  the default contexts miss arrows, and arrows ship. Declared (`declare
  function`) surface is covered by the defaults too.
- `require-description`: the block description is mandatory; a doc that
  only restates the signature is the thing this folder exists to reject.
- `require-param`, `require-returns`: parameters and returned values
  documented (a function with parameters and no doc block at all fails, so
  the two rules make `require-jsdoc` non-bypassable).
- `check-param-names`: `@param` names must match the signature.
- `check-tag-names`: tags come from the known vocabulary; a typo like
  `@retruns` does not pass silently.
- `require-hyphen-before-param-description`: `@param name - description` is
  the fixed shape, so diffs don't reformat param lines.

Policy (nothing checks the prose): doc comments carry what the signature
cannot — the non-finite input that flows through, the thrown whose
exception class the type does not name, the default the type does not show.
A restate-the-signature doc passes every linter in the stack and is still
the bug; review treats it as one.

Machine (eslint core comment rules):

- `capitalized-comments` at `error` (`always`, with
  `ignoreInlineComments` + `ignoreConsecutiveComments`): comment lines open
  capitalized; directives (`eslint-disable`) and URL-lead comments are
  exempt inside the rule itself.
- `no-warning-comments` at `error` for `todo`, `fixme`, `xxx`: the
  tripwire. Unfinished work is a fail, because tickets live in the
  tracker, not in the code — and "never downgrade this to get a build
  green" is a written rule, not a vibe.

### Coverage — the gate

```json
"test": "vitest run --coverage"
```

`vitest.config.ts` sets `coverage.thresholds` at 95 on **lines,
functions, branches and statements** — the run fails under 95 on any of
the four axes. Provider is `v8` (default; since vitest's AST-aware
remapping its accuracy matches istanbul). `coverage.include` names `src`
so never-imported sources appear in the report as uncovered, and
`coverage.exclude` removes the test files themselves, which would pad
their own axis. **Global aggregation is the default; per-file gating is
opt-in via `thresholds.perFile`** and deliberately off.

THE GATE IS TESTED, both sides:

- PASS (skeleton-suite, exit 0):
  `Statements 100% (6/6) · Branches 100% (2/2) · Functions 100% (3/3) ·
  Lines 100% (5/5)`
- FAIL (one branch and one function untested, exit 1):
  `Statements 71.42% (5/7) · Branches 50% (1/2) · Functions 75% (3/4) ·
  Lines 66.66% (4/6)` with one `ERROR: Coverage for ...` line per axis.

No threshold key beyond vitest's documented set is used ("reportOn"
options do not exist for this purpose). `coverage.reportOnFailure: true`
is set deliberately: a red build still writes its lcov report, so the
Coveralls upload shows the real number instead of going badge-less.

### Hygiene — spell check (typos)

`typos` checks every file for misspellings (typos 1.50.1, pinned in ci.yml;
configuration in the repo-root `.typos.toml`).

```bash
typos
```

Remedy: fix the spelling, or add the identifier to `.typos.toml` with a
reason (the config carries two: a ruff rule family name and a deliberate
example of a mistyped tag). Measured wall time: 0.02s on this repo.
THE GATE IS TESTED: a clean tree exits 0; a seeded misspelling fails:

```text
error: `recieve` should be `receive`
  ╭▸ ./proof-seed-typo.md:1:1
  │
1 │ recieve the calender
  ╰╴━━━━━━━
```

### Hygiene — markdown lint + link check

`markdownlint-cli2` lints every markdown file (v0.23.2; config in the
repo-root `.markdownlint-cli2.jsonc`) and `lychee` checks every link
(v0.24.2; config in the repo-root `lychee.toml`, retry then fail).

```bash
markdownlint-cli2 "**/*.md"
lychee --no-progress .
```

Remedy: fix the markdown or the link. The config carries four reasoned
entries (hand-wrapped prose, skill-doc headings, the centered banner, tab
indentation inside fenced shell). Measured wall times: markdown 0.3s,
links 1.0s. THE GATE IS TESTED: a clean tree exits 0; seeded violations
fail:

```text
markdownlint-cli2 "**/*.md":1 MD009/no-trailing-spaces Trailing spaces [Expected: 0 or 2; Actual: 3]
lychee: [ERROR] http://127.0.0.1:9/dead (at 1:1) | Connection refused
```

### Hygiene — secret scan (gitleaks)

`gitleaks` scans for committed credentials (v8.30.1, default rule set;
config in the repo-root `.gitleaks.toml`). CI scans the full git history
(`fetch-depth: 0`), so an already-committed secret is caught too; the local
runner scans the working tree with `--no-git`.

```bash
gitleaks detect --source . --redact     # CI: full history
gitleaks detect --no-git --redact       # local runner: working tree
```

Remedy: rotate the secret, purge it from history, and never allowlist a real
credential. Allowlist entries need a reason. Measured wall time: 0.2s on
this repo (20 commits). THE GATE IS TESTED: a clean tree exits 0 ("no leaks
found"); a seeded fake AWS key fails:

```text
Finding:     aws_access_key_id (aws-access-key-id)
Secret:      AKIA********************E/REDACTED
File:        proof-seed-secret.txt:1
```

### Hygiene — copy-paste detection (jscpd)

`jscpd` tokenizes every source file and fails above the duplication
threshold (v5.2.0; config in the repo-root `.jscpd.json`, threshold 5).

```bash
jscpd
```

Remedy: extract the shared code into one place. The config ignores four
intentionally-parallel shapes with reasons (template byte-copies, per-folder
CI files, per-folder runners, and the folder READMEs' shared hygiene
sections). Measured wall time: 0.04s on this repo. THE GATE IS TESTED: a
clean tree exits 0 (0.00% duplicated). The threshold measures the whole
tree, so the failure proof runs the same command on a scratch fixture with
two identical 10-line functions (58 of 120 tokens, 48% against the 5%
threshold) and records its exit code 1:

```text
Found 1 clones.
Clone found (python)
 - proof-dup-a.py [1:1 - 10:15] (10 lines, 58 tokens)
   proof-dup-b.py [1:1 - 10:15]
exit code: 1
```

### Hygiene — dependency advisories + licenses (osv-scanner)

`osv-scanner` scans every lockfile for known vulnerabilities and reports
dependency licenses against an allow-list (v2.5.1). This repository itself
carries no lockfiles, so the step lives in each folder's CI and runner: it
targets the initialized repository, where the lockfiles exist.

```bash
osv-scanner scan -r .
osv-scanner scan -r . --licenses="MIT,Apache-2.0,ISC,BSD-3-Clause,BSD-2-Clause,MPL-2.0,PSF-2.0,Python-2.0,0BSD"
```

Remedy: bump or replace the flagged dependency. License violations must be
resolved or justified in review; the osv-scanner exit codes carry the
verdict. Measured wall time: seconds (network-bound, advisory DB cached).
THE GATE IS TESTED: a seeded package-lock.json with lodash 4.17.4 fails
with five GHSA advisories; adding pm2 (AGPL-3.0) fails the license gate:

```text
| https://osv.dev/GHSA-fvqr-27wr-82fm | 6.5  | npm | lodash | 4.17.4 | 4.17.5 | package-lock.json |
advisories exit code: 1
| AGPL-3.0 | npm | pm2 | 5.1.0 | package-lock.json |
license exit code: 130
```

### Hygiene — own-artifact linting (shellcheck, shfmt, yamllint, actionlint)

The repository's own shell scripts and workflow files are linted with the
same severity as its code: shellcheck (v0.11.0), shfmt -d (v3.14.0),
yamllint (v1.38.0, config in the repo-root `.yamllint.yaml`), and
actionlint (v1.7.12) on every workflow file, including the per-folder ci.yml
templates.

```bash
for sh in $(git ls-files "*.sh"); do shellcheck "$sh"; done
for sh in $(git ls-files "*.sh"); do shfmt -d "$sh"; done
yamllint ./.github/workflows/*.yml ./*/ci.yml
actionlint ./.github/workflows/*.yml ./*/ci.yml
```

Remedy: fix the script or the workflow; yamllint deviations carry reasons in
`.yamllint.yaml`. Measured wall time: 0.2s. THE GATE IS TESTED: a clean tree
exits 0 (after fixing the findings this gate itself caught: an unguarded
rm -rf and shfmt formatting); seeded violations fail:

```text
shellcheck: SC2086 on the seeded unquoted variable (exit 1)
yamllint: proof-seed.yaml:2 syntax error (exit 1)
```

### Formatter

`prettier --check .` with zero shared config: the defaults plus the tool
chain are the single source of formatting truth. eslint's setup comment
documents why no stylistic lint rules coexist with it. `.prettierignore`
keeps generated code (`coverage/`, `node_modules/`) out of the check.

CI uploads `coverage/lcov.info` to Coveralls (`coverallsapp/github-action@v2`, free for public repos on the built-in GITHUB_TOKEN);
`reportOnFailure` keeps the upload on a red build, so the free badge
(`coveralls.io/github/OWNER/REPO/badge.svg`) shows the real number on
every commit. The init skill inserts the badge line into the new
repository's README.

## Commands

```bash
./run-gates.sh             # run every gate below, in parallel
npm ci                   # deterministic install against the committed lockfile
npm run format:check     # prettier --check .             — format gate
npm run typecheck        # tsc --noEmit                   — type gate (strict + the 8 flags)
npm run lint             # eslint .                       — lint gate (errors only, no warns)
npm test                 # vitest run --coverage           — the 95% gate, four axes
```

CI (`.github/workflows/ci.yml`) runs exactly these commands in this order,
after `npm ci`, on node 24 with actions/setup-node@v7.

## Trade-offs ("strict but staying usable")

- The inconveniencing tsc flags, named: `noUncheckedIndexedAccess` makes
  every index read `T | undefined` until you narrow (the noisiest flag in
  the table); `exactOptionalPropertyTypes` makes `undefined` different
  from "absent", so optional-property handling needs intent;
  `noPropertyAccessFromIndexSignature` forces bracket notation on records;
  `verbatimModuleSyntax` means type-only imports must say `import type`;
  `noImplicitReturns`, `noImplicitOverride`, `noFallthroughCasesInSwitch`
  and the unused pair are cheap. The package is strict-but-workable — the
  proof repo compiles clean under all of them.
- The jsdoc admin load is real: every export needs a doc block with a real
  description, matching param names and hyphens. Budget that upkeep, or
  the exported surface will churn the gate. The way out is not blanketing
  `allow` — it is writing the one sentence the signature cannot, per the
  policy above.
- Typed linting costs a project type pass on every `eslint .` run; fine at
  small scale, grows with the repo, editors recover it via caching. The
  alternative (dropping type information) is rejected — the typed rules
  are the point.
- The TODO tripwire failing CI is the feature: it moves unfinished work
  into the tracker. If a codebase must carry a true in-repo task marker,
  rewording under the tripwire is a visible, reviewable decision.
- The typescript pin (6.0.3) will trail the TypeScript majors: tseslint's
  support window governs, not hype. Bumping is a deliberate change with
  the two gate commands re-run.
- Node floor is 22 (`engines`), verified on 24: tseslint's supported range
  is `^18.18.0 || ^20.9.0 || >=21.1.0`, so the floor holds with margin. A
  team pinning node via Volta adds its own `volta` block — deliberately not
  in the template so the pin belongs to the team using it.

## The init skill

`init-typescript-repo/` initializes a new TypeScript repository with all of
this. Install: `scripts/install-skills.sh` (or copy the folder to
`~/.agents/skills/`). The templates are byte-identical copies —
`scripts/verify-sync.sh` fails if they drift.

## Sources for the verified shapes

- typescript-eslint flat-config + `projectService` shape and version
  support window: typescript-eslint.io, Getting Started / Typed Linting /
  Dependency Versions (`>=4.8.4 <6.1.0`).
- jsdoc rule names and granular-config language: eslint-plugin-jsdoc
  README (pinned 64.3.8 verified in node_modules).
- vitest coverage keys (`thresholds.*`, `perFile` default false, provider
  v8): vitest.dev Config → coverage.
- `spaced-comment` deprecation and comment-rule semantics: eslint.org
  Rules Reference (v10-era docs, installed 10.10.0).
