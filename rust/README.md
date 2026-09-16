# rust/ — the Rust strict baseline

The stack below is worked, not theoretical: it ran against a 90k-line
workspace until `cargo check` fails on any undocumented public item and
`cargo doc` fails on any broken doc link. Every deny carries its reason.

## What is enforced

### Linting — clippy

`Cargo.toml.example` carries the `[workspace.lints]` table:

- `clippy::all`, `pedantic`, `nursery`, `cargo` groups at `warn` with
  `priority = -1`, because an individual lint entry at the default priority 0
  overrides its group only when the group sits lower (cargo manifest reference).
- A shortlist of `restriction` picks: the failure modes specific to the code
  you are writing (in the phone app that was `unwrap_used`, `expect_used`,
  `panic`, `print_stdout`, `exit`...). Choose YOUR picks; every one gets a
  reason, per house rule. The template ships `allow_attributes_without_reason`
  as a pick: an allow without a why is the bug — the suppression outlives its
  reason and nothing records it. The suppression path stays
  `#[expect(lint, reason = "...")]`: a reasoned expect does not trip the pick,
  and an expect that stops firing fails the build on its own.
- Every blanket exception documented in the table; one-offs in code as
  `#[expect(lint, reason = "...")]` — `expect`, not `allow`, so an exception
  that stops being needed fails the build instead of rotting.
- `forbid` only where no legitimate code can trip the lint (the exemplar:
  `unsafe_code = "forbid"`); `deny` everywhere else, since forbid cannot be
  overridden even by an expect with a reason.
- `clippy.toml` sets `doc-valid-idents` so `clippy::doc_markdown` fires on
  real identifier noise and not on your domain nouns. Appending the `..`
  sentinel keeps clippy's 70-entry default; new house nouns get added there
  rather than backtick-unusual prose.

CI runs `cargo clippy --workspace --all-targets -- -D warnings` — so every
warn level here is an error in CI. The doc lints do not take that courtesy path.

### Documentation — rustdoc + rustc (deny）

- `[workspace.lints.rustdoc] all = "deny"`: the whole stable group in one
  entry — broken/private intra-doc links, invalid and unparsable code blocks,
  HTML tags in docs, bare URLs, unescaped backticks, redundant explicit
  links, private doc tests, missing crate-level docs. The nightly-only
  `missing_doc_code_examples` is deliberately outside the group: it churns
  with the channel and demands a runnable example on every documented item.
- `missing_docs = "deny"` under `[workspace.lints.rust]`: no undocumented
  public item compiles, in local builds too.
- Because rustdoc lints fire under `cargo doc` only (never under
  `cargo clippy`), CI adds a `Doc comments` job:
  `RUSTDOCFLAGS='-D warnings' cargo doc --workspace --no-deps`.

### Types

Rust's type system is the baseline; the strict additions are the deny lints
above plus `missing_debug_implementations`, `unreachable_pub`,
`trivial_casts`, `trivial_numeric_casts`, `unused_qualifications` at warn
(err-as-error in CI). Doc comments then carry what the signature cannot:
wire keys the serde rename hid, who sends what, defaults, absence behavior.

### Comments — machine + policy

Machine: the clippy/rustdoc doc lints above. Policy (no linter checks prose):
the four house rules — present state only; why-not-what; `#NNN` cited only
attached to a live constraint; nothing displays a number no server sends.
Ship them verbatim in the new repo's AGENTS.md (the template carries them).

Policy, enforced: a TODO or FIXME marker in Rust source fails the build —
the uniform house TODO policy (python fails the marker through FIX002,
TypeScript through no-warning-comments, go through godox). The rust half is
a grep step — `git grep -nE "TODO|FIXME" --untracked -- '*.rs' || test
$? -eq 1` — so any marker in tracked or new-but-untracked `*.rs` files
fails CI, and a scanner failure (corrupt index, bad pathspec) also fails
the step instead of inverting to a green build; there is no ignore mechanism — the remedy is to resolve the TODO, not to suppress
the gate.

### Coverage — the gate

```bash
cargo llvm-cov --workspace --fail-under-lines 95 --fail-under-regions 95 --fail-under-functions 95
```

Three axes, not one: the pinned cargo-llvm-cov (0.9.0) exposes fail-under
switches for lines, regions, and functions in its CLI reference
(`--fail-under-lines`, `--fail-under-regions`, `--fail-under-functions` —
`cargo llvm-cov --help`), so the gate holds all three at 95. Regions are
LLVM's branch-level coverage: an untested arm of a match or an if can pass
a line gate while failing a region gate. Measured on the template fixture:
a clean project sits at 100.00% on all three axes, and a seeded untested
function drops lines to 86.36%, functions to 75.00%, regions to 86.36% —
all three fail-under switches exit 1 on the same seed.

Add `llvm-tools-preview` to the CI toolchain; see `ci.yml`. THE GATE IS
TESTED: measured on the pinned toolchain (cargo-llvm-cov 0.9.0), a fixture
with every statement covered exits 0 at 100.00% TOTAL, and the same fixture
with one untested function exits 1 under the three-axis gate at
86.36%/75.00%/86.36% — the gate fails the build under 95% (that is its
acceptance test).

### Tests — mutation testing (cargo-mutants, scheduled nightly)

`cargo-mutants` mutates the workspace source (operators, literals, arm
bodies) and runs the test suite against each mutant: a mutant the tests do
not catch is behavior the suite never pinned down (v27.1.0, pinned in
mutation.yml — the scheduled workflow, not the PR path). The results file
`mutants.out/outcomes.json` carries the totals the floor reads; it is
disposable tool output, like `target/`.

The score floor is 85, checked from the results file: `cargo mutants`
exits nonzero whenever ANY mutant survives (its zero-missed CI mode), and
the template fixture provably carries equivalent mutants — `clamp` returns
the bound itself at the boundary, so mutating `value < low` to
`value <= low` cannot change behavior. A zero-missed gate is unmeetable
without restructuring the code, so the floor sits under the
equivalent-mutant headroom instead: any genuinely untested code drops the
score below it.

```bash
cargo mutants
python3 -c "import json, sys; s = json.load(open('mutants.out/outcomes.json')); score = 100 * s['caught'] // s['total_mutants']; print('mutation score %d%% (caught %d/%d, floor 85)' % (score, s['caught'], s['total_mutants'])); sys.exit(0 if score >= 85 else 1)"
```

Floor reason, from the first measured run on the template fixture: 19/21
caught = 90%, with the two misses the clamp equivalent mutants above. Why
nightly: a mutant run multiplies the test suite by the mutant count (14s
for 21 mutants on a three-function fixture; it scales with both), so it
cannot sit between a commit and a merge. `run-gates.sh` and the PR `ci.yml`
deliberately exclude it. Trade-off accepted: a surviving mutant waits up to
a day for the nightly run to flag it. Remedy: add a test that kills the
mutant. Measured wall time: 14s clean, 18s seeded. THE GATE IS TESTED: the
clean fixture scores 90% and the floor step exits 0; a seeded function with
no test drops the score below the floor and the floor step exits 1:

Visibility note: the nightly run's only failure signal is GitHub's
scheduled-run notification, which goes to the single account that created
or last edited the cron; scheduled workflows are also auto-disabled after
about 60 days of repo inactivity. Keep Actions notifications on for that
account and re-run via `gh workflow run mutation` if the nightly has not
fired recently.
Capacity note: the nightly job is capped at 60 minutes — free on public
repos, and on a private initialized repo it bills against the free
Actions minutes as the suite grows. When the suite outgrows 60 minutes
the run dies on the job timeout: that red is a capacity signal, not a
score-floor failure (the log shows the timeout, not the floor message).

```text
mutation score 90% (caught 19/21, floor 85)     # clean, exit 0
mutation score 73% (caught 19/26, floor 85)     # seeded, exit 1
```

### Hygiene — spell check (typos)

`typos` checks every file for misspellings (typos 1.50.1, pinned in ci.yml;
configuration in the repo-root `.typos.toml`).

```bash
typos
```

Remedy: fix the spelling, or add the identifier to `.typos.toml` with a
reason (the config carries five, each with its reason: a ruff rule
family name, the deliberate mistyped-tag example, the seeded-proof quote
words, and GNU grep's PCRE flag token from the typescript bidi step).
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
osv-scanner scan -r . --licenses="MIT,Apache-2.0,ISC,BSD-3-Clause,BSD-2-Clause,MPL-2.0,PSF-2.0,Unicode-3.0,Python-2.0,Unlicense,CC0-1.0,0BSD,Apache-1.1,BSD-3-Clause-Clear"
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

### Hygiene — supply-chain policy (cargo-deny: RustSec advisories, licenses, bans)

`cargo-deny` is the rust-native supply-chain engine on top of the
cross-language osv-scanner pair above (v0.20.2, install
`cargo install cargo-deny --locked --version 0.20.2`, config in `deny.toml`
with a reason on every entry). It adds what osv-scanner cannot see:
yanked releases (denied — a yanked release is a recall), unmaintained and
unsound advisories on direct dependencies, banned crates with their
replacement, duplicate-version convergence, and unknown registries or git
sources. CI runs one labeled step per check so a failure names its gate.

```bash
cargo deny check advisories
cargo deny check licenses
cargo deny check bans
```

Remedy: bump or replace the flagged crate; ignore an advisory only with its
parsed id and a reason carrying the review date; a truly unavoidable
duplicate version goes in `[bans] skip-tree` with its reason. Measured wall
time on the example project: advisories 0.9s (advisory DB cached), licenses
0.1s, bans 0.1s. THE GATE IS TESTED, every check both ways: the clean
example project exits 0 on all three; a seeded `chrono = "=0.4.19"` fails
the advisories check with

```text
error[vulnerability]: Potential segfault in `localtime_r` invocations
  ├ ID: RUSTSEC-2020-0159
  ├ Advisory: https://rustsec.org/advisories/RUSTSEC-2020-0159
exit code: 1
```

a seeded allow-list restricted to ISC alone fails the licenses check (exit
1), and a seeded `openssl = "0.10"` fails the bans check with

```text
error[banned]: crate 'openssl = 0.10.81' is explicitly banned
exit code: 2
```

Fail-closed on advisories: with the advisory database unavailable and
fetching disabled (`--offline` against an empty database path), the check
exits 1 instead of scanning without data —

```text
[ERROR] failed to get 'FETCH_HEAD' metadata: failed to get HEAD timestamp
```

and `deny.toml` adds `maximum-db-staleness = "P90D"`, so a cached database
older than 90 days fails the gate rather than scanning with stale data.

### Hygiene — unused dependencies (cargo-shear)

`cargo-shear` parses every source file with rust-analyzer's parser and
diffs the imports it finds against the dependencies the manifests declare:
a crate declared in `[dependencies]` that no source file imports is the
failing case (v1.13.4, pinned in ci.yml). CI runs it with
`--deny-warnings` — unused *optional* dependencies, empty files, and
unlinked files are warnings by default, and the house rule denies them.

```bash
cargo shear --deny-warnings
```

Detection limits, per its own docs: macro-generated imports are invisible
without `--expand` (nightly only, significantly slower), and misplaced
unit-test dependencies inside `#[cfg(test)]` cannot be detected. A crate the
tool cannot see used goes into the package's
`[package.metadata.cargo-shear] ignored` list — a suppress that suppresses
nothing is reported as redundant, so stale ignores surface on their own.
Remedy: remove the dependency, or document why the tool cannot see the use.
Measured wall time on the example project: 0.05s. THE GATE IS TESTED: the
clean example project exits 0; a seeded unused `serde` fails (exit 1):

```text
shear/unused_dependency
  × unused dependency `serde`
    ╰── not used in code
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

`cargo fmt --all -- --check` in CI. `rustfmt.toml` marks its nightly-only
options (`wrap_comments` and friends) if you adopt them; on a stable pin
leave the file minimal.

CI passes `--lcov --output-path lcov.info` and uploads it to Coveralls
(`coverallsapp/github-action@v2`, free for public repos on the
built-in GITHUB_TOKEN);
llvm-cov writes the report before it evaluates the gate (measured), so
the free badge (`coveralls.io/github/OWNER/REPO/badge.svg`) shows the
real number on every commit, red builds included. The init skill
inserts the badge line into the new repository's README.

## Commands

```bash
./run-gates.sh              # run every gate below, in parallel
rustup component add llvm-tools-preview
cargo clippy --workspace --all-targets -- -D warnings   # lint gate
RUSTDOCFLAGS='-D warnings' cargo doc --workspace --no-deps   # doc gate
cargo test --workspace                                  # also runs doc tests
cargo llvm-cov --workspace --fail-under-lines 95 --lcov --output-path lcov.info
cargo fmt --all -- --check                              # format gate
# ...and CI uploads the lcov.info to Coveralls for the free badge
```

Runner-CI parity: 21 runner entries <-> 21 CI gate steps (5 language gates + 16 hygiene gates, cargo-deny's three among them; the Coveralls upload, the doc job's rust-cache step, and the tool installs are not gates). The runner deliberately
excludes the nightly mutation gate (mutation.yml), so its absence there is
the documented decision, not a miss.

## Trade-offs ("strict but staying usable")

- CI tool installs: the pinned prebuilt binaries are checksum-verified
  where upstream publishes checksums (lychee, gitleaks, osv-scanner,
  actionlint, cargo-deny) and release-tag-pinned where none is published
  (typos, shellcheck, shfmt, cargo-mutants) — the residual risk is
  recorded in the install block and reviewed on every pin bump. yamllint is
  the one registry-install exception: GPL-3.0-or-later, deliberately excluded
  from the permissive-only python lockfile, installed by exact pin.
- `missing_docs` was found firing ~330 times on a workspace whose docs would
  have been name-restatements; the way out was not an allow but a bar — each
  doc must say what the signature cannot. If you are initializing a repo with
  a large existing surface, budget for that pass or lower to a
  documented-why `allow` on specific items only.
- `nursery` is the experimental group; it emits lints that later change. The
  toolchain pin makes the emission deterministic; a channel bump re-runs the
  gate and fixes what moved, in the same commit.
- `doc_markdown` false-positives are config, not prose edits: extend
  `doc-valid-idents` with the identifier spelled AS THE CODE SPELLS IT.

### Accepted gaps — signals no gate in this stack can catch

Stated as current facts, not a plan: nothing below is enforced today, and
each entry names what changes the answer.

- Cognitive complexity. Clippy has no cognitive-complexity rule; the close
  cousin `clippy::cognitive_complexity` measures a McCabe-style branching
  score, not Sonar's cognitive complexity, and it is not a stable thresholded
  gate here. What changes the answer: clippy shipping a cognitive-complexity
  restriction rule with a defensible threshold.
- Nesting-depth caps. No clippy/rustc lint counts nesting depth (the
  `nestif`-style signal). What changes the answer: a nesting-depth rule in
  clippy's stable set.
- Magic-number detection. Rust's type system keeps constants typed, but
  nothing in the clippy/rustc stack flags unnamed literals in logic the way
  eslint's no-magic-numbers does; rustc's `alert`-style lint does not exist.
  What changes the answer: a magic-number restriction lint in clippy.
- Repeated literal to constant. No clippy lint flags a string or number
  repeated across branches (the `goconst`/`no-duplicate-string` signal).
  What changes the answer: a repeated-literal rule in clippy.
- Class-size caps. Rust has no classes, and clippy's size family stops at
  functions (`clippy::too_many_lines`); struct surface and trait complexity
  have no cap lint. What changes the answer: a size-cap rule for impl blocks
  in clippy.
- Commented-out code detection. No clippy/rustc lint fires on commented-out
  code blocks (the `commented_code`-style signal). What changes the answer:
  a commented-out-code rule in clippy's stable set.
- SAST. The rust-native surface has no static security scanner in this
  baseline (semmle/CodeQL-style analysis is not a clippy lint). What changes
  the answer: a maintained rust-native SAST gate mainstream enough to pin.
- Test-style linting. Clippy's group lints cover shipped code shapes; test
  naming/assertion style (the `thelper`/`testifylint` signal) has no clippy
  rule. What changes the answer: test-style restriction lints in clippy.
- Assertion-less tests. Nothing static here detects a test whose body runs
  no assertion. The nightly mutation run covers the signal instead: an
  unpinned behavior survives as a mutant and fails the mutation-score floor
  (see the mutation-testing section).
- Import-layer contracts and cycles. `cargo` denies cyclic crate
  dependencies at the package boundary (a workspace cannot compile one), but
  within a crate there is no layer contract lint (the depguard/depcruiser
  signal). What changes the answer: an import-layer lint in clippy or a
  mainstream rust-native layer checker.
- Dependency-graph cycles between crates: see the line above — cargo fails
  the build on a crate cycle, so the signal exists; no separate gate is
  needed and none is claimed.

Refused families, not gaps: coupling/cohesion dashboards and
Halstead/Maintainability-Index/NPath were reviewed and refused — they are
not accepted gaps and must not be built (`tasks/expand-lint-gates/notes/refusal-decisions.md` records the reasons).

## The init skill

`init-rust-repo/` initializes a new Rust repository with all of this. Install:
`scripts/install-skills.sh` (or copy the folder to `~/.agents/skills/`). The
templates are byte-identical copies — `scripts/verify-sync.sh` fails if they
drift.
