---
name: init-shell-repo
description: >-
  Initializes a new shell (bash) repository with the strictest workable
  enforcement stack: ShellCheck at its default style severity with the man
  page's two optional checks and reasoned rc directives, shfmt gated by the
  .editorconfig via `shfmt -d .`, a kcov-based coverage-gate.sh that fails
  the build below 95% line coverage with recorded proofs, release binaries
  pinned by sha256 digest in CI, and the shared hygiene set (typos,
  markdownlint, lychee, gitleaks, jscpd, TODO grep, yamllint, actionlint).
  Use when the user asks to initialize, bootstrap, or set up a new shell
  project or repository with strict linting and a code-coverage gate.
---

# Initialize a strict shell repository

Sets up a brand-new bash repository so that ShellCheck fails the build on
any finding at its default (style) severity, `shfmt -d .` fails on any
formatting drift, and `./coverage-gate.sh` fails the build below 95% line
coverage measured by kcov. Read this reference repo's `shell/README.md` for
the reasoning behind every piece; the steps below assume that reasoning and
only record the work.

# Preconditions

- `git` and `bash` (4.3 or newer; kcov needs bash's debug trap).
- A C toolchain or Homebrew to install kcov from source or a bottle; Linux
  CI installs kcov's pinned prebuilt binary, so local macOS proofing uses
  Homebrew.

# Steps

1. Create the repository: `git init`, then scaffold `src/` with the first
   library (a `#!/usr/bin/env bash` script of functions) and `test/` with
   the runner template copied in step 2.
2. Copy every template from this skill's `templates/` directory into the
   new repository root, byte-identical (they pair with the canonical files
   by the entries in `scripts/verify-sync.sh` of the strictest-setups
   repo): `.shellcheckrc -> .shellcheckrc`, `.editorconfig ->
   .editorconfig`, `coverage-gate.sh -> coverage-gate.sh` (then
   `chmod +x coverage-gate.sh`), `run-gates.sh -> run-gates.sh` (then
   `chmod +x run-gates.sh`), `ci.yml -> .github/workflows/ci.yml`,
   `test/run_tests.sh -> test/run_tests.sh` (then `chmod +x
   test/run_tests.sh`), `src/greeter.sh -> src/greeter.sh`, and the
   shared hygiene copies (`lychee.toml`, `.typos.toml`,
   `.markdownlint-cli2.jsonc`, `.gitleaks.toml`, `.jscpd.json`,
   `.yamllint.yaml`) -> repository root.
3. Write the example tests into `test/run_tests.sh` where the template's
   expectations sit: replace the example assertions with the project's,
   keeping the runner's harness (the `expect` helper, the `fail`
   accumulator, the trailing `exit "$fail"`). The template ships one
   example assertion against the shipped `src/greeter.sh` example library
   so the suite passes before the first real test is written — a
   deliberate deviation from the configs-only template sets of the other
   folders, because shell has no package manager or build system to
   generate a test target and the coverage gate needs a runnable suite to
   exist.
4. Install the pinned tools: `brew install shellcheck shfmt kcov` (macOS)
   or download the same pinned release binaries the copied `ci.yml`
   installs on Linux — shellcheck 0.11.0, shfmt 3.14.0, kcov v42's
   prebuilt binary. Verify the versions: `shellcheck --version`,
   `shfmt --version`, `kcov --version`.
5. Run every gate and make each one pass or fail for a known, acceptable
   reason:
   - `for sh in $(git ls-files "*.sh"); do shellcheck "$sh"; done`
   - `shfmt -d .`
   - `./test/run_tests.sh`
   - `./coverage-gate.sh`
   ShellCheck's default severity is style — every finding fails the
   build; write the code the rule asks for — never disable a rule to
   pass the build without a written reason in `.shellcheckrc`.
6. Review the enabled surface against what the project actually is: the
   two optional checks in `.shellcheckrc` (quote-safe-variables,
   check-unassigned-uppercase) may be dropped with a one-line reason if
   they prove noisy for the project's style, and the todo-policy gate may
   be widened to other extensions the project carries. The default
   severity, the `.editorconfig` format gate, and the coverage gate are
   not negotiable.
7. Wire the free coverage badge: the `ci.yml` template already uploads
   kcov's cobertura report to Coveralls (`coverallsapp/github-action@v2`
   runs on the built-in GITHUB_TOKEN and auto-detects cobertura reports).
   Add to the new repository's README:
   `![coverage](https://coveralls.io/github/OWNER/REPO/badge.svg?branch=main)`
   with OWNER/REPO replaced by the GitHub slug, after the first push. No
   repository secret is needed; a private repo would add a Coveralls
   repo token instead.
8. Commit everything in one bootstrap commit (message style is the repo's
   choice from here on).

# Gates

- After step 5, ALL the commands run green (or a documented,
  pre-existing decision explains any red).
- `scripts/verify-sync.sh` in this reference repo still passes: templates
  must be edits of the canonical files, not independent forks.
- If `./coverage-gate.sh` cannot run (kcov cannot instrument the suite,
  or jq is missing), STOP and report the tooling failure; do not proceed
  with the gate quietly missing.
