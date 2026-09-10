---
name: init-typescript-repo
description: >-
  Initializes a new TypeScript repository with the strictest workable
  enforcement stack: eslint with typescript-eslint's strictTypeChecked typed
  preset, a hand-picked strict slice of eslint-plugin-jsdoc, eslint core
  comment rules, a tsconfig.json with strict plus the eight beyond-strict
  flags, the todo tripwire, prettier, and a CI workflow running the five
  gates. Vitest coverage thresholds enforce >=95% on lines, functions,
  branches and statements, and the gate has been proven to fail a build
  under 95%. Use when the user asks to initialize, bootstrap, or set up a
  new TypeScript project or repository with strict linting, documentation
  enforcement, and a code-coverage gate.
---

# Initialize a strict TypeScript repository

Sets up a brand-new TypeScript repository so that `tsc --noEmit` fails on
any of the strict-plus-eight compiler flags, `eslint .` fails on an
undocumented export, a doc comment that restates the signature, or a comment
that announces unfinished work, and `npm test` fails below 95% on any of the
four coverage axes. Read this repo's `typescript/README.md` for the
reasoning behind every piece; the steps below assume that reasoning and only
record the work.

# Preconditions

- Node 22 or newer (`node --version`; the engines floor in the template) and
  a working `npm` with network access to the registry.
- You know the target directory and the package name (kebab-case).

# Steps

1. Create the repository directory, `git init` there, and nothing else: the
   template carries the manifest, so no `npm init` runs.
2. Copy every template from this skill's `templates/` directory into the new
   repository root: `tsconfig.json -> tsconfig.json`,
   `eslint.config.mjs -> eslint.config.mjs`,
   `vitest.config.ts -> vitest.config.ts`,
   `package.json -> package.json`,
   `.prettierignore -> .prettierignore`,
   `ci.yml -> .github/workflows/ci.yml`.
3. Substitute exactly one marked value: package.json's
   `"name": "rename-this-package"` becomes the project's own kebab-case
   name. Keep the devDependency pins verbatim — they are exact versions
   chosen so typescript-eslint supports the pinned typescript (see README),
   and adding or ranging them re-opens the compatibility question the pin
   closed.
4. Write `.gitignore` with `node_modules/`, `dist/`, `coverage/` — one dir
   per line.
5. `npm install` to materialize package-lock.json from the exact pins, and
   commit the lockfile: CI's `npm ci` gate only pins what the lock carries.
6. Create a minimal gate-conforming skeleton: `src/index.ts` exporting one
   documented function and `src/index.test.ts` covering every line, branch
   and function of it. The doc comment must carry a block description (a
   bare `@param` pair will not pass `jsdoc/require-description`), matching
   parameter names, and `@param name - description` hyphens. Templates for
   these two files are NOT shipped: write them fresh, because the coverage
   gate only stays honest when the skeleton is the project's own.
7. Run every gate and make each one pass or fail for a known, acceptable
   reason, in this order:
   - `npm run format:check`
   - `npm run typecheck`
   - `npm run lint`
   - `npm test` (fine under 95% on any of lines / functions / branches /
     statements)
   `jsdoc/require-description` means an undocumented exported function
   FAILS the build; write the doc — never delete the rule to pass the
   build. The coverage FAIL output names the axis and the aggregate; fix
   the tests, not the thresholds.
8. Wire the free coverage badge: the `ci.yml` template already uploads
   coverage/lcov.info to Coveralls (`coverallsapp/github-action@v2` runs
   on the built-in GITHUB_TOKEN, free for a public repo). Add to the new repository's README:
   `![coverage](https://coveralls.io/github/OWNER/REPO/badge.svg?branch=main)`
   with OWNER/REPO replaced by the GitHub slug, after the first push. No repository secret is needed; a private repo would add a Coveralls
   repo token instead.
9. Commit everything in one bootstrap commit (message style is the repo's
   choice from here on).

# Gates

- After step 7, ALL four commands run green (or a documented, pre-existing
  decision explains any red), and `npm test` exits 0 at 100% on the
  skeleton.
- `scripts/verify-sync.sh` in this reference repo still passes: templates
  must be edits of the canonical files, not independent forks. (One
  template, `.prettierignore`, is not yet paired in that script; treat the
  canonical file as its source of truth until the pairing lands.)
- If `npm install` cannot fetch dependencies or vitest cannot run, STOP and
  report the tooling failure; do not proceed with the gate quietly missing.
