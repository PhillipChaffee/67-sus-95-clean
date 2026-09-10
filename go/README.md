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

echo "coverage-gate: PASS — total statement coverage ${pct}% ≥ ${required}%"
rm -f "${profile}"
```

Two things `go test` does not give you and the script supplies itself:

1. **A fail-under switch**: `go test` has none — `-coverprofile` stops at
   printing percentages. The awk comparison (total line of
   `go tool cover -func`) is the fail-under; `golangci-lint` cannot invent
   one either, which is why the gate is a script, not a config key.
2. **Gate-the-suite semantics**: a red `go test` is a red gate — coverage is
   never reported on unproven code, and the profile is kept for
   `go tool cover -html=cover.out` debugging while a pass deletes it.

**THE GATE IS TESTED.** Recorded runs on a scratch module: suite fully
covered → `PASS — total statement coverage 100.0% ≥ 95%` (exit 0, profile
deleted); an uncovered helper added → `FAIL — total statement coverage is
25.0%, required 95%` (exit 1, profile kept); a compile-broken suite →
`FAIL — go test failed` (exit 1, profile kept).

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
