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

### Complexity — cognitive (arborist)

```bash
arborist --threshold 15 --exceeds-only --gitignore --languages rust .
```

Cognitive complexity is the only complexity metric this stack gates (the
consolidation decision). The gate is **arborist-cli 0.2.1**, installed
`cargo install --locked --version 0.2.1 arborist-cli` — the most
spec-faithful *measured* rust implementation of the SonarSource
cognitive-complexity whitepaper (17/23 spec probes match at this pin).
Clippy's own `cognitive_complexity` restriction lint was considered and
refused as the spec gate: it self-disclaims in source — "left in
`restriction` so as to not mislead users into using this lint as a
measurement tool" — and counts flat decisions only.

- Threshold: **15** — Sonar's own S3776 default, the parity anchor every
  language in this baseline gates at (go gocognit 15, python complexipy 15,
  shell omen 15, TS sonarjs 15). arborist has no config file, so the
  threshold lives in the gate command (ci.yml and run-gates.sh); raise it
  only with a written reason there.
- Measured divergences from the whitepaper, recorded honestly: flat `else
  if` chains inflate (a 4-way chain scores 9 where the spec counts 4,
  monotonic in chain depth — the conservative direction); labeled breaks
  and indirect recursion each under-count by one; a nested fn's body
  scores inside its enclosing function at nesting 0, not as a separate
  entry.
- Binary gate: exit 0 when nothing exceeds; exit 1 when any function
  scores above the threshold (a `!` marks the row); exit 2 on a missing
  file. Scope is the whole tree — tests included, no carve-out;
  `--gitignore` keeps `target/` out (traversal honors .gitignore inside a
  git checkout) and `--languages rust` keeps the gate scoped to rust
  sources.
- Supply chain: the version is pinned with `--locked`; the tool is an
  external binary, not a dev-dependency, so none of its ~300-package tree
  enters the gated repository's lockfile or its cargo-deny/osv-scanner
  gates. The trade-offs section records the lockfile review.

THE GATE IS TESTED (recorded runs on the template fixture at the pin):

```text
clean tree                          -> exit 0
seeded fn scoring 21 (6 nested ifs) -> "21 !", exit 1 (threshold 15)
score-15 seed (5 nested ifs)        -> exit 0 (boundary: 15 passes, 16+ fails)
missing.rs                          -> "error: file not found", exit 2
```

### File length — the effective-lines gate

```bash
./effective-lines-gate.sh
```

Clippy has no file-length rule (verified against the pinned toolchain's
full lint list: the only lines-count option, `too-many-lines-threshold`,
caps *functions* — `clippy::too_many_lines`; `max-include-file-size` is a
byte cap for `include_bytes!` payloads; rustfmt is layout-only). The gate
is a script on the coverage-gate.sh pattern that carries its own counter —
a stdlib-only Rust program embedded in the bash script and compiled by the
rustc the pinned toolchain already provides, so the repository it gates
gains no Rust source its linters, coverage, or dependency gates would have
to see.

Effective lines count a physical line unless it is blank, is a whole-line
comment (opens with `//` — covering `///` and `//!` — or the nesting-aware
`/* */` scanner leaves no code outside the comment), or lies inside a `/*
*/` block; attributes count as code. The counting is deliberately
line-shaped, not a token stream: the `//` and `/*` tokens inside a string
literal — a raw string `r#"..."#` most visibly — are classified as
comment markers, so such lines can shift the count a line or two, always
in the conservative (lower-count) direction. A file that cannot be read
fails the gate: fail closed, never silently.

- Threshold: **1000 effective lines** — ratified per-language to match
  python's cap; Sonar's per-language file defaults are 1000 *raw* lines,
  so 1000 *effective* is stricter than any of them (blanks and comments
  drop out). No parity with TypeScript's 300.
- Scope: every `*.rs` file from the repository root, skipping exactly what
  cargo never reviews: hidden directories, `target/` (build output), and
  `vendor/` (vendored third-party sources). Generated files are exempt:
  the canonical `// Code generated ... DO NOT EDIT.` header line in the
  leading comment section. Test files are capped identically: no test
  carve-out (a table too big for the cap is data and belongs in a
  fixture).
- Remedy: split the file by responsibility (clippy::too_many_lines stays
  as the per-function axis).

THE GATE IS TESTED (recorded runs on scratch fixtures):

```text
1001 effective lines                                     -> FAIL (exit 1)
exactly 1000 effective                                   -> PASS (exit 0)
1091 physical = 1000 effective (54 whole-line comments,
  36 blank lines excluded)                               -> PASS (exit 0)
1003 physical, everything inside nested /* */ blocks     -> 0 effective, PASS
999 attribute lines + 3 fn lines = 1002 effective        -> FAIL (attributes count)
1004 physical raw-string lines opening with //           -> 4 effective, PASS
   (the documented imprecision, conservative direction)
generated file with the DO NOT EDIT header at 1001
  effective                                              -> skipped (exempt)
tests/over_test.rs with 1002 effective                   -> FAIL (exit 1): no test carve-out
target/gen/over.rs with 1001 effective                   -> skipped (target/)
chmod-000 file                                           -> "could not run; fix
  the tooling, never skip the gate"                      -> FAIL (exit 1): never a silent pass
```

### Documentation — rustdoc + rustc (deny）

- `[workspace.lints.rustdoc] all = "deny"`: the whole stable group in one
  entry — broken/private intra-doc links, invalid and unparsable code blocks,
  HTML tags in docs, bare URLs, unescaped backticks, redundant explicit
  links, private doc tests, missing crate-level docs. The nightly-only
  `missing_doc_code_examples` is deliberately outside the group: it churns
  with the channel and demands a runnable example on every documented item.
- `missing_docs = "deny"` under `[workspace.lints.rust]`: no undocumented
  public item compiles, in local builds too.
- `clippy::doc_paragraphs_missing_punctuation` (restriction, warn — err-as-
  error in CI): the one mechanical doc-*substance* rule that exists in any
  rust tooling — every paragraph of a doc comment ends in punctuation, the
  Google-style period rule. Adopted after the lint ran clean on the
  template workspace (exit 0, zero findings on idiomatic docs) and proved
  to fail a seeded unpunctuated paragraph (exit 101 under `-D warnings`).
  Completeness lints (`missing_errors_doc`, `missing_panics_doc`) are
  pedantic picks already on; rustdoc's `all = deny` owns the structural
  side. Prose quality beyond punctuation is review, not lints.
  THE GATE IS TESTED: the template workspace with idiomatic docs exits 0
  under `-D warnings`; a seeded paragraph without terminal punctuation
  fails with "doc paragraphs should end with a terminal punctuation mark"
  (exit 101), and the one measured false-positive shape (a paragraph
  ending inside a code span) is recorded in Trade-offs.
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
a grep step — a fail-closed grep (captured exit code: matches and errors fail, only "no matches" passes): `git grep --untracked --no-recurse-submodules -nE "TODO|FIXME" -- '*.rs' || rc=$?; test "$rc" -eq 1` — so any marker in tracked or new-but-untracked `*.rs` files
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
Scoring semantics: the denominator is every mutant the run generated,
including classes no test can exercise (unviable builds, timeouts) —
those sit in the denominator and deflate the score, so the floor is
strict against tool friction as well as genuine gaps; that is
deliberate and calibrated from the fixture's clean run, where every
mutant class is testable.

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
yamllint ./.github/workflows/*.yml $(find . -mindepth 2 -maxdepth 2 \( -name "ci.yml" -o -name "mutation.yml" \) -not -path "./.github/*" | tr "\n" " ")
actionlint ./.github/workflows/*.yml $(find . -mindepth 2 -maxdepth 2 \( -name "ci.yml" -o -name "mutation.yml" \) -not -path "./.github/*" | tr "\n" " ")
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
cargo install --locked --version 0.2.1 arborist-cli     # once, for the cognitive gate
arborist --threshold 15 --exceeds-only --gitignore --languages rust .   # cognitive gate
./effective-lines-gate.sh                               # file-length gate (max 1000)
cargo fmt --all -- --check                              # format gate
# ...and CI uploads the lcov.info to Coveralls for the free badge
```

Runner-CI parity: 23 runner entries <-> 23 CI gate steps (7 language gates
and 16 hygiene gates, cargo-deny's three among them; the Coveralls upload,
the doc job's rust-cache step, and the tool installs are not gates). The
runner deliberately excludes the nightly mutation gate (mutation.yml), so
its absence there is the documented decision, not a miss.

## Trade-offs ("strict but staying usable")

- CI tool installs: the pinned prebuilt binaries are checksum-verified
  where upstream publishes checksums (lychee, gitleaks, osv-scanner,
  actionlint, cargo-deny) and release-tag-pinned where none is published
  (typos, shellcheck, shfmt, cargo-mutants) — the residual risk is
  recorded in the install block and reviewed on every pin bump. yamllint is
  the one registry-install exception: GPL-3.0-or-later, deliberately excluded
  from the permissive-only python lockfile, installed by exact pin.
- arborist-cli is a crates.io registry build (`cargo install --locked
  --version 0.2.1`), not a digest-pinned release download: the pin is the
  crate version plus the 300-package lockfile the crate itself ships, so
  the tree is reproducible byte-for-byte. Its lockfile was reviewed at
  adoption (osv-scanner + license scan against the shipped lock): 18 known
  advisories across 8 packages, all in the self-updater's reqwest/tokio/
  rustls/tar network stack — unreachable from the analysis path the gate
  runs (pure filesystem) and all carrying upstream fixes, re-check on any
  pin bump; two licenses sit outside the house allow-list (Zlib on
  foldhash, CDLA-Permissive-2.0 on webpki-root-certs) and are tool-tree
  only — nothing of this tree enters the gated repository's lockfile,
  which is exactly why arborist must never become a dev-dependency. The
  shipped `self_update` 0.43 self-updater is dormant: only the `update`
  subcommand touches the network, and against a cargo-installed binary it
  refuses to self-update and only version-checks; the gate command never
  invokes it. Residual: no checksum anchor beyond crates.io's own; CI
  compiles the tree on every runner (~3 min measured locally, rust-cache
  does not persist `~/.cargo/bin`) — accepted for the template; a
  digest-pinned prebuilt download is the alternative if that cost bites.
- `doc_paragraphs_missing_punctuation` has one measured false-positive
  shape: a paragraph whose last character sits inside a code span (it ends
  with `` `foo()` ``, not with a sentence) fires. Remedy: end the
  paragraph with prose, or `#[expect(lint, reason = "...")]`. Bullets and
  headings are exempt (measured).
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
