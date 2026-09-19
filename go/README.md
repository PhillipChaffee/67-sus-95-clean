# go/ — the Go strict baseline

The stack below is verified, not theoretical: it was exercised against
golangci-lint **v2.13.2** (config verified against that binary's own schema,
including the failure mode of a made-up settings key being rejected), its
coverage gate was run twice on a scratch module — passing at 100.0% and
failing at 25.0% — and its file-length and doc-substance gates were proven
both ways on scratch fixtures (records in the sections below). Every
enable below carries its reason.

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
- Size-and-shape caps, each with its threshold and reason in the config:
  `gocognit` (cognitive complexity, min 15 — Sonar's own Go S3776 default
  as a parity anchor, inside golangci-lint's reference config band
  "Default: 30 (but we recommend 10–20)"; nesting-weighted control flow is
  the smell, remedy: extract a function), `funlen`
  (60 lines / 40 statements, the documented defaults), `nestif` (nested if
  depth, min 5), `mnd` (unnamed literals in logic, default checks, nothing
  whitelisted — `usestdlibvars` already covers the http-context literals),
  `goconst` (a literal written 3+ times becomes a constant), and
  `interfacebloat` (max 10 methods). Cyclomatic complexity is deliberately
  absent: cognitive complexity is the only complexity metric this stack
  gates (the consolidation decision). Proven both ways on the template
  fixture: the clean project runs 0 issues; a sixteen-branch function with
  cognitive complexity 16 passes at the old threshold of 30 and fails at 15
  with output naming the linter and file (`cognitive complexity 16 of func
  Cog is high (> 15)`).
- Hygiene and security linters, each with its policy in the config:
  `godox` (TODO and FIXME markers fail the build — the uniform house TODO
  policy; BUG stays out as a tracker state; remedy: resolve the TODO, there
  is no ignore mechanism), `nolintlint` (a suppression names its lint and
  carries an explanation; a stale one fails the run — no bare nolint),
  `bidichk` (bidi and confusable characters in source fail the build),
  `gosec` (the default check list, nothing disabled — none needed on the
  template fixture; disable a check only with a reason in the table),
  `depguard` (the import-layer contract: shipped code does not import
  `unsafe`, the guarantee rust's `unsafe_code = "forbid"` carries), and
  `gomodguard_v2` (blocked modules carry their recommended replacement, so
  the error names the fix; `gomodguard` itself is deprecated since v2.12.0).
  Proven both ways on the template fixture: a bare TODO, a bare nolint, a
  bidi character, a hardcoded credential with a weak hash, an `unsafe`
  import, and a blocked module import each fire with output naming the
  linter and file.
- Test-style linters: `thelper` (a test helper that takes `*testing.T` must
  call `t.Helper()` first — otherwise failure traces point at the helper,
  not the caller), `testifylint` (canonical testify assertion style, all
  checkers on), and `tparallel` (a parallel subtest requires a parallel
  parent, or the subtests serialize). All three run on their strictest
  defaults; any disabled check carries a reason. Proven both ways on the
  template fixture: a missing `t.Helper()`, a non-canonical assertion, and
  a parallel subtest under a serial parent each fire with output naming the
  linter and file.
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

### Documentation & comments — revive `exported` + godoclint

The presence floor is revive's `exported` rule (fired in validation as
`exported: exported function NoDoc should have comment or be unexported`):
every exported package, function, method, type, const and var needs a doc
comment, and the default rules revive carries stay on through
`enable-default-rules: true`.

On top of presence, godoclint's two ratified rules (built into the pinned
golangci-lint since v2.5.0 — zero new dependencies) fail the build on doc
comments that lie about their own syntax:

- `deprecated`: a paragraph starting with a deprecation-like marker must
  start it exactly with `Deprecated:` plus one trailing space — the form
  go tooling parses. Fired in validation as `deprecation note should be
  formatted as "Deprecated: "` on a seeded `DEPRECATED:` paragraph; the
  canonical form does not fire. godoclint parses with go/doc/comment, so it
  only sees paragraph-initial markers; a lowercase `deprecated:` in the
  middle of a paragraph is caught by gocritic's `deprecatedComment` checker
  instead — the two linters cover the shapes the other cannot parse.
- `no-unused-link`: a `[name]: URL` link definition in a doc comment must
  be referenced. Fired in validation as `godoc has unused link ("Orphaned
  Page")` on a seeded orphaned definition; a referenced definition and a
  valid `[Symbol]` shorthand stay silent.

godoclint runs with `default: none` and only these two rules enabled — the
schema's `basic` set would also switch on require-doc, start-with-name and
friends, a completeness layer that is refused for go: canonical go doc
comments are prose-first (go.dev/doc/comment), so a python-style
args/returns gate is a category error, not a gap. There is also no stable
checker for *inline comment prose quality* — the why-not-what /
present-state-only house rules remain human policy, shipped in the new
repo's AGENTS.md by the init skill. (godot, the nearest mechanical
candidate — punctuation policing — is refused; the policy lives on
content, not final periods.)

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

### File length — the effective-lines gate

```bash
./effective-lines-gate.sh
```

`.golangci.yml` has no file-length rule to turn on: golangci-lint's
linters cap functions (`funlen`) and line length (`lll`), never files.
The gate is a script on the coverage-gate.sh pattern that carries its own
counter — a `go/token` scanner with `ScanComments`, embedded in the script
and run from a temporary stdlib-only module, so the repository it gates
gains no Go source that its linters, coverage, or dependency gates would
have to see.

Effective lines count a physical line unless it is blank, is a whole-line
comment, or lies inside a block comment — the same definition eslint gives
TypeScript's max-lines (`skipBlankLines` + `skipComments`). Because the
scanner tokenizes, a `//` inside a raw string literal is never mistaken
for a comment and block-comment interiors are never mistaken for code. A
file the scanner cannot read cleanly counts every non-blank line: fail
closed, never silently.

- Threshold: **750 effective lines** — Sonar's Go S104 default
  (`GO_DEFAULT_FILE_LINE_MAX = 750`), the only directly citable
  effective-lines number for Go.
- Exemption: a file whose section before the package clause carries the
  canonical `// Code generated ... DO NOT EDIT.` header line
  (go.dev/s/generatedcode) — the house principle that generated code is
  not reviewed here.
- Scope: the scan walks exactly what `go build ./...` sees — dot-prefixed,
  underscore-prefixed, `vendor`, and `testdata` directories are skipped.
- `_test.go` files are capped identically: no test carve-out. A table too
  big for the cap is data and belongs in a fixture.

Remedy: split the file by responsibility (`funlen` stays as the
per-function axis). THE GATE IS TESTED. Recorded runs on scratch fixtures:

```text
751 effective lines -> over.go: 751 effective lines exceeds the maximum of 750 (exit 1)
776 physical = 701 effective (55 whole-line comments + 20 blank lines excluded) -> PASS (exit 0)
901 effective lines under the generated-code header -> PASS (exempt, exit 0)
raw string with 11 "//"-looking lines -> string lines count as code: 753 effective -> FAIL (exit 1)
same shape as real whole-line comments -> 742 effective -> PASS (exit 0)
big_test.go with 751 effective lines -> FAIL (exit 1): no test carve-out
internal/big.go with 751 effective lines -> FAIL (exit 1): nested packages are scanned
.git/, vendor/, testdata/ over-cap files -> skipped (exit 0)
```

### Hygiene — spell check (typos)

`typos` checks every file for misspellings (typos 1.50.1, pinned in ci.yml;
configuration in the repo-root `.typos.toml`).

```bash
typos
```

Remedy: fix the spelling, or add the identifier to `.typos.toml` with a
reason (the root config is the union this repo needs — a ruff rule family
name, the deliberate mistyped-tag example, the seeded-proof quote words,
and GNU grep's PCRE flag token from the typescript bidi step — and the
python/, typescript/, go/, and rust/ folder canonicals carry the trimmed
subsets a bootstrapped repo can actually hit, so a genuine misspelling the
root union covers cannot hide behind an inert allowance there).
Measured wall time: 0.02s on this repo.
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
osv-scanner scan -r . --licenses="MIT,Apache-2.0,ISC,BSD-3-Clause,BSD-2-Clause,MPL-2.0,PSF-2.0,Unicode-3.0,Python-2.0,Unlicense,CC0-1.0,0BSD,Apache-1.1,BSD-3-Clause-Clear,LGPL-3.0-only,BlueOak-1.0.0,CC-BY-3.0"
```

The allow-list is the shared house list; its wider entries (MPL-2.0,
PSF-2.0, Unicode-3.0, Unlicense, CC0-1.0, 0BSD, Apache-1.1,
BSD-3-Clause-Clear) carry the python lockfile's dependency licenses, so
one list runs identically in every folder's CI and runner.

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
yamllint ./.github/workflows/*.yml $(ls ./*/ci.yml ./*/mutation.yml 2>/dev/null)
actionlint ./.github/workflows/*.yml $(ls ./*/ci.yml ./*/mutation.yml 2>/dev/null)
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
go mod tidy -diff                                                       # go-native unused-dependency gate: fails when the module files and the imports disagree; remedy: go mod tidy
golangci-lint fmt --diff                                                # format gate
go vet ./...                                                            # vet
golangci-lint run                                                       # lint gate
go test ./...                                                           # tests
./coverage-gate.sh                                                      # coverage gate
./effective-lines-gate.sh                                               # file-length gate
```

Runner-CI parity: 20 runner entries <-> 20 CI gate steps (9 language gates including the schema check + 11 hygiene steps; the tool installs are not gates). The runner deliberately
The runner carries no mutation gate: the mutation-testing
family is a documented refusal for go (see the accepted-gaps section), so
nothing nightly exists to exclude.

## Trade-offs ("strict but staying usable")

- CI tool installs: the pinned prebuilt binaries are checksum-verified
  where upstream publishes checksums (lychee, gitleaks, osv-scanner,
  actionlint, cargo-deny) and release-tag-pinned where none is published
  (typos, shellcheck, shfmt, cargo-mutants) — the residual risk is
  recorded in the install block and reviewed on every pin bump. yamllint is
  the one registry-install exception: GPL-3.0-or-later, deliberately excluded
  from the permissive-only python lockfile, installed by exact pin.
- **Statement coverage only.** `go tool cover` counts statements; Go ships
  no branch-coverage mode, and 95% of statements still allows an untested
  branch of every if. Recorded here rather than papered over — the gate
  measures what the toolchain can see.
- **No fail-under on `go test`** (see above) — the script is the switch.
- **The file-length gate compiles its counter at run time.** The embedded
  scanner builds in a temp module on every gate run (a stdlib-only
  compile; about a second) in exchange for carrying no Go source inside
  the gated repository. A scanner that cannot run fails the gate with the
  tooling error printed — never a silent pass. The generated-code
  exemption trusts the canonical header line: a hand-written file claiming
  it is out of scope the same way `go build ./...` treats it.
- `gocritic`'s whole-tag enables mean a new stable check arriving in a
  gocritic bump can fire on old code. The pinned version makes that
  deterministic; the bump policy is fix-what-moved in the same commit.
- `revive :: exported` on a large undocumented surface is a one-time paying
  of doc debt, same as rust's `missing_docs`; budget the pass or write the
  comment that says what the signature cannot.
- `err113` bans mid-flight error construction, not just dynamic %v messages;
  libraries that deliberately build error values per occurrence are the
  pattern it forbids. Strict by decision.
- **Unreachable exported functions.** golang.org/x/tools' `deadcode`
  command was investigated and refused: it reports unreachable functions
  but exits 0 on findings at both tested versions (v0.40.0 and v0.50.0,
  recorded with actual command output in the epic's
  `tasks/expand-lint-gates/notes/decision-deadcode.md`), so it is not a binary gate and no
  wrapper substitutes for one. Unused unexported functions stay covered by
  the `unused` linter; unreachable *exported* functions are a signal no
  gate in this stack catches. What changes the answer: a deadcode exit-code
  mode in x/tools.

### Accepted gaps — signals no gate in this stack can catch

Stated as current facts, not a plan: nothing below is enforced today, and
each entry names what changes the answer.

- Commented-out code. gocritic has a `commentedOutCode` checker today, but
  it carries the `experimental` tag — the same false-positive budget reason
  the config leaves the experimental tag off, so the checker does not ride
  the enabled `style`/`performance` tags. What changes the answer: the
  checker graduating out of experimental.
- Assertion-less tests. Nothing static here detects a test whose body runs
  no assertion — it passes vacuously. The coverage gate sees reached
  statements, not assertions. What changes the answer: mutation testing.
- Mutation testing. Two go tools exist with recent activity (gremlins, last
  release May 2024; avito-tech/go-mutesting, commits through 2025), but
  neither ships a proven mutation-score floor that is a binary gate the way
  mutmut and cargo-mutants are for python and rust, and adopting one here
  without the gate-contract proofs would be the half state those workstreams
  refused. What changes the answer: one of these tools reaching a stable
  pin with score-floor semantics.
- Doc-comment substance beyond presence and syntax. revive `exported` plus
  godoclint's `deprecated`/`no-unused-link` are go's mechanical ceiling:
  nothing enforces that a doc comment says more than the signature
  restates, and a python-style args/returns completeness layer is a
  category error for prose-first doc comments (go.dev/doc/comment), so it
  is refused rather than recorded as missing. What changes the answer: a
  maintained tool that mechanically enforces substance for go doc
  comments.
- Refused families, not gaps: coupling/cohesion dashboards and
  Halstead/Maintainability-Index/NPath were reviewed and refused — they are
  not accepted gaps and must not be built (`tasks/expand-lint-gates/notes/refusal-decisions.md` records the reasons).

## The init skill

`init-go-repo/` initializes a new Go repository with all of this. Install:
`scripts/install-skills.sh` (or copy the folder to `~/.agents/skills/`). The
templates are byte-identical copies — `scripts/verify-sync.sh` fails if they
drift.
