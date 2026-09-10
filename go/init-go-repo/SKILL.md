---
name: init-go-repo
description: >-
  Initializes a new Go repository with the strictest workable enforcement
  stack: golangci-lint v2 with the standard set plus hand-picked strict extras
  (gocritic style+performance tags, revive default rules with the exported
  rule), gofumpt as the formatter gate, a pinned tool version, a
  pinned Go toolchain in go.mod, and a coverage-gate.sh script that fails the
  build below 95% statement coverage with recorded proofs. Use when the user
  asks to initialize, bootstrap, or set up a new Go project or repository with
  strict linting, documentation enforcement, and a code-coverage gate.
---

# Initialize a strict Go repository

Sets up a brand-new Go repository so that `golangci-lint run` fails on any
undocumented exported item (revive `exported`), the gofumpt format check and
go vet run as errors, and `./coverage-gate.sh` fails the build below 95%
total statement coverage. Read this reference repo's `go/README.md` for the
reasoning behind every piece; the steps below assume that reasoning and only
record the work.

# Preconditions

- A `go` command at 1.21 or newer (the pinned toolchain is then fetched
  automatically under the default `GOTOOLCHAIN=auto`, go.dev/doc/toolchain).
- You know the target directory and the module name (`go mod init` takes it).

# Steps

1. Create the repository: `go mod init <module-path>`, then `git init` unless
   already done.
2. Copy every template from this skill's `templates/` directory into the new
   repository root, byte-identical (they pair with the canonical files by the
   entries in `scripts/verify-sync.sh` of the strictest-setups repo):
   `.golangci.yml -> .golangci.yml`, `coverage-gate.sh -> coverage-gate.sh`
   (then `chmod +x coverage-gate.sh`), `ci.yml ->
   .github/workflows/ci.yml`.
3. Pin the toolchain: `go mod edit -go=1.27.1 -toolchain=1.27.1` (match the
   current stable at bootstrap time for both lines, and keep the
   `GOTOOLCHAIN: go1.27.1` line in the copied ci.yml in sync with it).
4. Install the pinned linter:
   `go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.13.2`
5. Run every gate and make each one pass or fail for a known, acceptable
   reason:
   - `golangci-lint config verify`
   - `go build ./...`
   - `golangci-lint fmt --diff`
   - `go vet ./...`
   - `golangci-lint run`
   - `go test ./...`
   - `./coverage-gate.sh`
   revive `exported` means an undocumented exported item FAILS
   `golangci-lint run`; write the doc comment — never delete the rule to
   pass the build.
6. Review the hand-picked linters in `.golangci.yml` against what the project
   actually is (if it never touches HTTP, `noctx` rests; if it does not build
   dynamic errors, `err113` rests), and drop those with a one-line reason in
   the config. The standard set, revive/exported, gocritic tags, gofumpt and
   the coverage gate are not negotiable.
7. Wire the free coverage badge: the `ci.yml` template already uploads
   cover.out to Codecov (`codecov-action@v7`, tokenless for a public repo).
   Add to the new repository's README:
   `![coverage](https://codecov.io/gh/OWNER/REPO/graph/badge.svg?branch=main)`
   with OWNER/REPO replaced by the GitHub slug, after the first push. If the
   org requires upload tokens, have the user create `CODECOV_TOKEN` in repo
   secrets and add `token: ${{ secrets.CODECOV_TOKEN }}` to the upload step.
8. Commit everything in one bootstrap commit (message style is the repo's
   choice from here on).

# Gates

- After step 5, ALL seven commands run green (or a documented, pre-existing
  decision explains any red).
- `scripts/verify-sync.sh` in this reference repo still passes: templates
  must be edits of the canonical files, not independent forks.
- If `./coverage-gate.sh` cannot run (a package cannot be instrumented, or
  the environment lacks the go toolchain), STOP and report the tooling
  failure; do not proceed with the gate quietly missing.
