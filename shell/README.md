# shell/ — the shell strict baseline

The stack below is verified, not theoretical: it was exercised against
ShellCheck **0.11.0**, shfmt **3.14.0**, and kcov (Homebrew 43_1 on macOS
for the recorded proofs; the CI template installs v42's prebuilt Linux
binary — v43 publishes none — and the gate parses kcov's documented
coverage.json schema, identical across both). Its coverage gate was run
three times on a scratch project — passing at 100.00%, failing at 85.71%,
and failing on a red suite. Every enable below carries its reason.

## What is enforced

### Linting — ShellCheck

`.shellcheckrc` is file-wide directive syntax (the keys ShellCheck
documents: disable, enable, extended-analysis, external-sources, source,
source-path, shell):

- **No severity is set — that is the strict setting.** ShellCheck's
  default severity is `style`, the strictest of its four levels (error,
  warning, info, style); `-S error` would *loosen* the gate. Fatality
  comes from exit codes: any finding at the active severity exits 1 and
  fails the build.
- `source-path=SCRIPTDIR` resolves `source` statements relative to the
  checked script; `external-sources=true` follows them. The default
  (false) exists only because ShellCheck started as a remote service for
  checking untrusted scripts; the man page: safe to enable "for normal
  development".
- Two optional checks enabled, exactly the pair the shellcheck man page's
  own strict example rc enables — `quote-safe-variables` and
  `check-unassigned-uppercase` — the officially-authored
  strict-but-workable baseline. The other nine optional checks stay off:
  the official wiki warns optional checks are "more subjective rather
  than more comprehensive, and may conflict with each other", and
  `enable=all` is documented for debugging and evaluation. (That
  `require-variable-braces`/SC2250 is too noisy for a clean repo is
  community experience, not an official claim — recorded here as a
  judgment call.)
- The dialect is not pinned globally: ShellCheck deduces it per file from
  the shebang, so bash scripts get full bash checking and POSIX sh
  scripts get portability warnings. Sourced libraries without a shebang
  carry a `# shellcheck shell=bash` directive — the documented
  alternative to blanket SC2039/SC2030/SC2031 disables.
- Per-instance suppression is a scoped in-file directive; a global
  `disable=` in the rc would need a written reason next to it, and this
  config needs none. Silencing parser errors is cosmetic anyway — a
  parser error still stops ShellCheck at the error.
- The pinned binary is the enforcement contract: CI downloads release
  v0.11.0 and verifies the sha256 digest the GitHub release API records
  for the asset (`8c3be12b…` for `shellcheck-v0.11.0.linux.x86_64.tar.xz`);
  bump the pin only re-running the gates and fixing what moved in one
  commit.

### Types

A documented refusal: no static type checker or annotation checker for
shell exists with official standing. ShellCheck self-describes as "a shell
script static analysis tool" giving warnings and suggestions; its only
annotation surface is `# shellcheck` directives (no type annotations);
shfmt's man page claims only `bash -n`-grade syntax checking. The
strictest available "type surface" is exactly this stack: ShellCheck's
static analysis (unquoted expansions, unassigned variables, dead code,
SC2034/SC2059-class data errors) plus shfmt's exhaustive static parse.
Recorded here rather than invented around.

### Documentation & comments

No stable checker for shell comment or doc-comment prose exists — the
ShellCheck rule index carries no doc-comment content rule (SC2148, "add a
shebang", is the nearest comment-adjacent check), and the doc generators
under that name have no official docs or releases to pin. The house
comment rules (why-not-what, present state only, no caller references)
remain human policy, shipped in the new repo's AGENTS.md by the init
skill. Machine enforcement stays where shellcheck does have it: a script
without a shebang is a finding, and `shell=bash` directives on sourced
libraries are checkable facts.

### Coverage — the gate

```bash
./coverage-gate.sh
```

The script is the whole gate — the star of this folder:

```bash
#!/usr/bin/env bash
#
# Coverage gate for a strict shell repository: fails when total line
# coverage from kcov is below 95%.
#
# kcov instruments the suite with bash's debug trap (PS4/BASH_XTRACEFD)
# and writes a coverage.json with a percent_covered value — but it ships
# no fail-under switch (the --limits flag only colorizes HTML), so this
# script is the gate: it parses every report kcov produced and compares
# the minimum against the threshold.
#
# A failing suite fails the gate too — coverage is never reported on an
# unproven suite. The suite runs twice: once plainly for a trustworthy
# exit status (kcov's exit-code propagation for the covered program is
# undocumented), then under kcov.
#
# This is line coverage only: kcov counts executed lines, and no
# branch-coverage mode exists for shell (kcov issue #27, open — see the
# README's coverage section). The reports are kept on both branches: on
# failure for coverage/index.html debugging, and on success so the CI's
# Coveralls upload step can turn the cobertura.xml report into the free
# coverage badge.
#
# Usage: run from the repository root: ./coverage-gate.sh
set -u -o pipefail

readonly required=95
readonly out_dir=coverage

if ! command -v jq >/dev/null 2>&1; then
	echo "coverage-gate: FAIL — jq is required to read kcov's coverage.json and is not installed" >&2
	exit 1
fi

if ! ./test/run_tests.sh; then
	echo "coverage-gate: FAIL — test suite failed" >&2
	exit 1
fi

if ! kcov --clean --exclude-path=test "${out_dir}" ./test/run_tests.sh; then
	echo "coverage-gate: FAIL — kcov run failed; reports kept at ${out_dir}" >&2
	exit 1
fi

# One coverage.json per covered program; a suite that spawns scripts
# writes their directories too. Fail closed when none was produced, and
# gate on the minimum across reports — the strictest honest number when
# more than one program was instrumented.
min=""
while IFS= read -r report; do
	pct=$(jq -r '.percent_covered' "${report}")
	if [ -z "${pct}" ] || [ "${pct}" = "null" ]; then
		echo "coverage-gate: FAIL — unreadable percent_covered in ${report}" >&2
		exit 1
	fi
	if [ -z "${min}" ] || awk -v a="${pct}" -v b="${min}" 'BEGIN { exit !(a + 0 < b + 0) }'; then
		min="${pct}"
	fi
done < <(find "${out_dir}" -name coverage.json)
if [ -z "${min}" ]; then
	echo "coverage-gate: FAIL — kcov produced no coverage.json under ${out_dir}" >&2
	exit 1
fi

if ! awk -v got="${min}" -v need="${required}" 'BEGIN { exit !(got + 0 >= need + 0) }'; then
	echo "coverage-gate: FAIL — total line coverage is ${min}%, required ${required}%; reports kept at ${out_dir}" >&2
	exit 1
fi

echo "coverage-gate: PASS — total line coverage ${min}% ≥ ${required}% (reports kept at ${out_dir} for the CI upload)"
```

Three things kcov does not give you and the script supplies itself:

1. **A fail-under switch**: kcov has none — `--dump-summary` prints
   percentages and `--limits` only colorizes HTML. The awk comparison
   against the minimum `percent_covered` across every report is the
   fail-under; the fixed-point `+ 0` comparison is the pattern bats-core's
   own CI uses for the same parse-and-compare problem.
2. **Gate-the-suite semantics**: a red `./test/run_tests.sh` is a red
   gate — coverage is never reported on unproven code. The suite runs
   twice (plainly, then under kcov) because kcov's exit-code propagation
   for the covered program is undocumented; the plain run is the truth
   about the suite, the kcov run is the measurement.
3. **Fail-closed parsing**: no reports, an unreadable report, or a
   missing jq each fail the gate — a gate that cannot read its evidence
   does not pass on that evidence's absence.

The reports are kept on both branches: failure keeps them for
`coverage/index.html` debugging, and success keeps them so the CI
Coveralls upload can turn the cobertura report into the badge.

**THE GATE IS TESTED.** Recorded runs on a scratch project (a `lib/`
library sourced by a `test/run_tests.sh` runner, the test directory
excluded from measurement): suite fully covered → `PASS — total line
coverage 100.00% ≥ 95%` (exit 0, reports kept); an uncovered helper added
→ `FAIL — total line coverage is 85.71%, required 95%` (exit 1, reports
kept); an assertion flipped red → `FAIL — test suite failed` (exit 1,
reports kept).

### Hygiene — spell check (typos)

`typos` checks every file for misspellings (typos 1.50.1, pinned in
ci.yml; configuration in the repo-root `.typos.toml`).

```bash
typos
```

Remedy: fix the spelling, or add the identifier to `.typos.toml` with a
reason. THE GATE IS TESTED on this repo (a seeded misspelling fails with
`error: 'recieve' should be 'receive'` naming the file and position).

### Hygiene — markdown lint + link check

`markdownlint-cli2` lints every markdown file (v0.23.2; config in the
repo-root `.markdownlint-cli2.jsonc`) and `lychee` checks every link
(v0.24.2; config in the repo-root `lychee.toml`, retry then fail).

```bash
markdownlint-cli2 "**/*.md"
lychee --no-progress .
```

Remedy: fix the markdown or the link; deviations carry reasons in the
configs. THE GATE IS TESTED on this repository's own CI (the hygiene
workflow runs both against this repo on every push).

### Hygiene — secret scan (gitleaks)

`gitleaks` scans for committed credentials (v8.30.1, default rule set;
config in the repo-root `.gitleaks.toml`). CI scans the full git history
(`fetch-depth: 0`), so an already-committed secret is caught too; the
local runner scans the working tree with `--no-git`.

```bash
gitleaks detect --source . --redact     # CI: full history
gitleaks detect --no-git --redact       # local runner: working tree
```

Remedy: rotate the secret, purge it from history, and never allowlist a
real credential. THE GATE IS TESTED on this repository's own CI (the
hygiene workflow scans the full history of every push).

### Hygiene — copy-paste detection (jscpd)

`jscpd` tokenizes every source file and fails above the duplication
threshold (v5.2.0; config in the repo-root `.jscpd.json`, threshold 5).

```bash
jscpd
```

Remedy: extract the shared code into one place. THE GATE IS TESTED on
this repository's own CI (the hygiene workflow runs it on every push,
and it polices the deliberate template byte-copies it ignores by
configuration).

### Hygiene — TODO policy (fail-closed grep)

A TODO or FIXME marker in shell source fails the build — the uniform
house TODO policy (python fails the marker through ruff FIX002, go
through godox, rust and shell through a grep step). Shell has no lint
rule for it, so the gate is rust's fail-closed grep shape.

```bash
rc=0; git grep --untracked --no-recurse-submodules -nE 'TODO|FIXME' -- '*.sh' || rc=$?; test "$rc" -eq 1
```

Remedy: resolve the TODO, there is no ignore mechanism. The shape is
fail-closed — the exit code is captured because a plain `||` cannot
express the gate: git grep exits 0 on matches, 1 on no matches, and
errors above that, so only "no matches" (exit 1) passes; matches and
errors both stay red. The option order matters: git parses a
post-pattern `--untracked` as a revision (exit 128, verified on git
2.50.1), and `--no-recurse-submodules` neutralizes a local
`submodule.recurse=true` that would otherwise reject `--untracked`.
THE GATE IS TESTED: a bare TODO in a `.sh` file fails the step with
the file and line (`seed.sh:2:# TODO: resolve this marker`); removing
it goes green. The runner's own gate string quote-splits the pattern
(`"TOD""O|FIX""ME"`) because the runner is itself a `*.sh` file the
gate scans — unsplit, the literal regex bytes would self-match and the
gate could never go green.

### Hygiene — own-artifact linting (yamllint, actionlint)

The repository's workflow files are linted with the same severity as its
code: yamllint (v1.38.0, config in the repo-root `.yamllint.yaml`) and
actionlint (v1.7.12) on every workflow file. ShellCheck and shfmt would
be redundant here as "artifact" gates — for this folder they ARE the
language gates.

```bash
yamllint ./.github/workflows/*.yml ./*/ci.yml
actionlint ./.github/workflows/*.yml ./*/ci.yml
```

Remedy: fix the workflow; yamllint deviations carry reasons in
`.yamllint.yaml`. THE GATE IS TESTED on this repository's own CI (every
folder's ci.yml template runs through both on every push).

### Formatter — shfmt

`shfmt -d .` is the man page's own CI pattern: exit 1 with a diff when
formatting differs. The formatter options live in `.editorconfig` —
shfmt applies EditorConfig options when no parser/printer CLI flag is
given, so the gate needs no flags and the config is the single source of
truth. The options are the Google shell style shfmt documents (`-i 2`,
`-ci`, `-bn`) expressed in EditorConfig keys, plus `simplify` — the
strictest formatter analogue. `keep_padding` is deprecated for removal
in shfmt's next major version and is left unset; `function_next_line`
and `minify` are left unset (Google style keeps braces on the function
line; minified shell is unreadable).

The gate script keeps the kcov reports on BOTH branches (deleting on
success would break badge-on-red), and CI uploads the cobertura report
to Coveralls (`coverallsapp/github-action@v2`, free for public repos on
the built-in GITHUB_TOKEN — the reporter auto-detects cobertura reports
by the `**/*/cobertura.xml` glob, which matches kcov's report layout
exactly; the upload is not a gate — `continue-on-error` keeps a
coveralls.io flake from reddening an otherwise-green build). The free
badge (`coveralls.io/github/OWNER/REPO/badge.svg`) shows the real
number on every commit, red builds included. The init skill inserts the
badge line into the new repository's README.

## Commands

```bash
./run-gates.sh                 # run every gate below, in parallel
for sh in $(git ls-files "*.sh"); do shellcheck "$sh"; done  # lint gate
shfmt -d .                     # format gate
./test/run_tests.sh            # tests
./coverage-gate.sh             # coverage gate
brew install shellcheck shfmt kcov  # local tool install (see ci.yml for the pinned CI downloads)
```

Runner-CI parity: 12 runner entries <-> 12 CI gate steps (4 language
gates + 8 hygiene steps; the tool installs are not gates). No
advisories/license steps exist to mirror: osv-scanner scans dependency
lockfiles, a shell repository carries none, and the pinned scanner exits
128 on a manifest-less tree (verified with v2.5.1). The runner carries
no mutation gate: no mutation-testing tool ships a proven score floor
for shell, a documented refusal (see the accepted-gaps section).

## Trade-offs ("strict but staying usable")

- **Line coverage only.** kcov counts executed lines; shell has no
  branch-coverage mode, and 95% of lines still allows an untested branch
  of every if. Recorded here rather than papered over — the gate
  measures what the tool can see.
- **No fail-under in kcov** (see above) — the script is the switch.
- **Two provenances for kcov**: CI installs v42's prebuilt Linux binary
  (v43 publishes no Linux release assets), while macOS locals install
  Homebrew's 43. The gate parses kcov's documented coverage.json schema,
  identical across both; the recorded proofs ran on 43_1. A Homebrew
  release matching a new kcov version is what collapses the two.
- **Two runs of the suite in the gate.** kcov's exit-code propagation
  for the covered program is undocumented, so the gate trusts the plain
  run's exit status and only measures under kcov. Cost: a few seconds of
  duplicate execution on a small suite.
- `check-unassigned-uppercase` fires on any uppercase variable ShellCheck
  cannot see assigned (sourced or inherited). The repo-wide convention
  this stack implies: lowercase script-local variables, uppercase
  reserved for exported environment values. Strict by decision; the init
  skill lets a project drop the check with a one-line reason.
- **No third-party lint action.** luizm/action-sh-checker is acknowledged
  — not endorsed — by mvdan/sh and pins no tool versions itself;
  ludeeus/action-shellcheck is referenced by no official ShellCheck or
  shfmt page. CI downloads pinned release binaries instead, verified
  against the digests the release API records.

### Accepted gaps — signals no gate in this stack can catch

Stated as current facts, not a plan: nothing below is enforced today,
and each entry names what changes the answer.

- No type system. ShellCheck's static analysis is the ceiling; there is
  no annotation or inference layer to enable. What changes the answer: a
  maintained shell type checker with official standing.
- No doc-comment gate. Nothing mechanical checks comment prose quality
  or requires a header comment per script (SC2148 requires only the
  shebang). The house comment rules stay human policy. What changes the
  answer: a stable, pinned doc-comment checker for shell.
- No `set -euo pipefail` enforcement. No ShellCheck rule requires the
  flag set (SC2164 and SC2312 catch nearest-by effects, not the policy).
  What changes the answer: a ShellCheck rule keyed on the missing set
  flags.
- No dependency gates. osv-scanner advisories and license checks need a
  lockfile manifest; a shell repository has none (the pinned scanner
  exits 128 on a manifest-less tree, verified with v2.5.1). What changes
  the answer: a dependency manifest format for shell that osv-scanner
  can scan.
- Mutation testing. A survey of the shell ecosystem found no mutation
  tool at all — the maintained coverage-adjacent candidates (bashcov,
  kcov, shellspec) are measurement-only, and nothing ships a proven
  score floor that is a binary gate the way mutmut and cargo-mutants
  are for python and rust. What changes the answer: one reaching a
  stable pin with score-floor semantics.
- Refused tools, not gaps: bashcov was investigated and refused as the
  coverage tool (Ruby >= 3.2 runtime per its gemspec; Linux-only CI
  matrix per its own workflow; and — verified against its `bin/bashcov`
  source — its `SimpleCov.at_exit` override only formats the report and
  never re-runs SimpleCov's threshold check, so `minimum_coverage`
  cannot fail a bashcov run and an external gate is needed anyway).
  shellspec/shellcov ("not yet launched") and westurner/shellcov
  (created 2026, unproven) were refused for maturity. `enable=all` for
  ShellCheck optional checks is refused on the official wiki's own
  warning that they are subjective and may conflict.

## The init skill

`init-shell-repo/` initializes a new shell repository with all of this.
Install: `scripts/install-skills.sh` (or copy the folder to
`~/.agents/skills/`). The templates are byte-identical copies —
`scripts/verify-sync.sh` fails if they drift.
