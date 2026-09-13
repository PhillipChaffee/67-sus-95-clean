# go/ — the Go strict baseline

The stack below is verified, not theoretical: it was exercised against
golangci-lint **v2.13.2** (config verified against that binary's own schema,
including the failure mode of a made-up settings key being rejected), and
its coverage gate was run twice on a scratch module — passing at 100.0% and
failing at 25.0%. Every enable below carries its reason.

## What is enforced

### Linting — golangci-lint v2

`.golangci.yml` is a `version: "2"` config (the quoted string matters: v1 keys
error out instead of silently misparsing once the version is declared):

- `default: standard` keeps errcheck, govet, ineffassign, staticcheck and
  unused — the vet-and-staticcheck surface that no Go repo should drop.
- Hand-picked extras, each with a reason in the config: `misspell`,
  `predeclared`, `unconvert`, `wastedassign`, `usestdlibvars`, `nilnil`,
  `noctx`, `err113`, `gocritic` (with `enabled-tags: [style, performance]` —
  the two stable-ish families; `experimental`/`opinionated` are left off for
  their false-positive budget), and `revive` with
  `enable-default-rules: true` plus the `exported` rule widened by its two
  additive flags (`check-private-receivers`, `check-public-interface`).
- `issues.max-issues-per-linter: 0` and `max-same-issues: 0`: the report is
  never capped or deduplicated — a gate that stops listing after 50 findings
  lies about the state of the tree.
- The pinned binary is the enforcement contract: install with
  `go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.13.2`
  (pinned in README and CI alike), run `golangci-lint config verify` to
  schema-check the file, and bump the pin only re-running the gates and
  fixing what moved in one commit.

### Types

`go vet ./...` and the standard set's staticcheck do the type-level checks;
`go build ./...` proves compilation. Go has no `--strict` switch beyond this
surface — the vet/staticcheck pair IS the strict mode, and the extra linters
above (predeclared, unconvert, wastedassign) carry the "beyond strict" picks.

### Documentation & comments — revive `exported`

The machine enforcement is revive's `exported` rule (fired in validation as
`exported: exported function NoDoc should have comment or be unexported`):
every exported package, function, method, type, const and var needs a doc
comment, and the default rules revive carries stay on through
`enable-default-rules: true`. There is no stable checker for *inline comment
prose quality* — the why-not-what / present-state-only house rules remain
human policy, shipped in the new repo's AGENTS.md by the init skill. (godot,
the nearest mechanical candidate — punctuation policing — is refused; the
policy lives on content, not final periods.)

### Coverage — the gate

```bash
./coverage-gate.sh
```

The script is the whole gate — the star of this folder:

```bash
#!/usr/bin/env bash
#
# Coverage gate for a strict Go repository: fails when total statement
# coverage is below 95%.
#
# `go test -coverprofile` writes the profile, `go tool cover -func` prints
# per-package counts plus a `total:` line, and awk compares that total
# against the threshold. A failing `go test` fails the gate too — coverage
# is never reported on an unproven suite.
#
# This is statement coverage only: `go tool cover` counts statements, and
# the Go toolchain ships no branch-coverage mode (see the README's coverage
# section for the consequences). The profile is kept in every path: on
# failure for `go tool cover -html=cover.out`, and on success so the CI's
# Coveralls upload step can turn it into the free coverage badge.
#
# Usage: run from the repository (module) root: ./coverage-gate.sh
set -u -o pipefail

readonly required=95
readonly profile=cover.out

if ! go test "-coverprofile=${profile}" -coverpkg=./... ./...; then
	echo "coverage-gate: FAIL — go test failed; profile kept at ${profile} for debugging" >&2
	exit 1
fi

total=$(go tool cover "-func=${profile}" | tail -n 1)
if [[ -z "${total}" ]]; then
	echo "coverage-gate: FAIL — 'go tool cover' produced no total line; profile kept at ${profile}" >&2
	exit 1
fi
pct=$(printf '%s\n' "${total}" | awk '{print $NF}' | tr -d '%')
if [[ -z "${pct}" ]] || ! awk -v got="${pct}" -v need="${required}" 'BEGIN { exit !(got + 0 >= need + 0) }'; then
	echo "coverage-gate: FAIL — total statement coverage is ${pct:-(unreadable)}%, required ${required}%; profile kept at ${profile}" >&2
	exit 1
fi

echo "coverage-gate: PASS — total statement coverage ${pct}% ≥ ${required}% (profile kept at ${profile} for the CI upload)"
```

Two things `go test` does not give you and the script supplies itself:

1. **A fail-under switch**: `go test` has none — `-coverprofile` stops at
   printing percentages. The awk comparison (total line of
   `go tool cover -func`) is the fail-under; `golangci-lint` cannot invent
   one either, which is why the gate is a script, not a config key.
2. **Gate-the-suite semantics**: a red `go test` is a red gate — coverage is
   never reported on unproven code, and the profile is kept on both branches: failure keeps it for
   `go tool cover -html=cover.out` debugging, and success keeps it so the
   CI Coveralls upload can turn it into the badge.

**THE GATE IS TESTED.** Recorded runs on a scratch module: suite fully
covered → `PASS — total statement coverage 100.0% ≥ 95%` (exit 0, profile
deleted); an uncovered helper added → `FAIL — total statement coverage is
25.0%, required 95%` (exit 1, profile kept); a compile-broken suite →
`FAIL — go test failed` (exit 1, profile kept).

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
osv-scanner scan -r . --licenses="MIT,Apache-2.0,ISC,BSD-3-Clause,BSD-2-Clause"
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

`golangci-lint fmt --diff` checks gofumpt, a backward-compatible strictening
of gofmt — one gate covering gofmt. Verified v2 behavior: formatter drift is
NOT reported by `golangci-lint run` (formatters live in their own config
section and their own command), which is why the CI job runs `fmt --diff`
explicitly.

The gate script keeps `cover.out` on BOTH branches (the old delete-on-
success behavior broke badge-on-red), and CI uploads it to Coveralls
(`coverallsapp/github-action@v2`, free for public repos on the built-in
GITHUB_TOKEN). The Go profile format (`golang`) is in Coveralls'
supported list, so the free badge
(`coveralls.io/github/OWNER/REPO/badge.svg`) shows the real number on
every commit, red builds included. The init skill inserts the badge
line into the new repository's README.

## Commands

```bash
./run-gates.sh              # run every gate below, in parallel
go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.13.2  # pinned tool
golangci-lint config verify                                             # schema check
go build ./...                                                          # compiles
golangci-lint fmt --diff                                                # format gate
go vet ./...                                                            # vet
golangci-lint run                                                       # lint gate
go test ./...                                                           # tests
./coverage-gate.sh                                                      # coverage gate
```

## Trade-offs ("strict but staying usable")

- **Statement coverage only.** `go tool cover` counts statements; Go ships
  no branch-coverage mode, and 95% of statements still allows an untested
  branch of every if. Recorded here rather than papered over — the gate
  measures what the toolchain can see.
- **No fail-under on `go test`** (see above) — the script is the switch.
- `gocritic`'s whole-tag enables mean a new stable check arriving in a
  gocritic bump can fire on old code. The pinned version makes that
  deterministic; the bump policy is fix-what-moved in the same commit.
- `revive :: exported` on a large undocumented surface is a one-time paying
  of doc debt, same as rust's `missing_docs`; budget the pass or write the
  comment that says what the signature cannot.
- `err113` bans mid-flight error construction, not just dynamic %v messages;
  libraries that deliberately build error values per occurrence are the
  pattern it forbids. Strict by decision.

## The init skill

`init-go-repo/` initializes a new Go repository with all of this. Install:
`scripts/install-skills.sh` (or copy the folder to `~/.agents/skills/`). The
templates are byte-identical copies — `scripts/verify-sync.sh` fails if they
drift.
