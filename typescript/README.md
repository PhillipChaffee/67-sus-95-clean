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

```
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
options do not exist for this purpose; `coverage.reportOnFailure` defaults
to false and stays unset).

### Formatter

`prettier --check .` with zero shared config: the defaults plus the tool
chain are the single source of formatting truth. eslint's setup comment
documents why no stylistic lint rules coexist with it. `.prettierignore`
keeps generated code (`coverage/`, `node_modules/`) out of the check.

CI uploads `coverage/lcov.info` to Codecov (`codecov-action@v7`, free for public repos — tokenless on a new org);
`reportOnFailure` keeps the upload on a red build, so the free badge
(`codecov.io/gh/OWNER/REPO/graph/badge.svg`) shows the real number on
every commit. The init skill inserts the badge line into the new
repository's README.

## Commands

```bash
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
