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
  reason, per house rule.
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

### Coverage — the gate

```bash
cargo llvm-cov --workspace --fail-under-lines 95
```

Add `llvm-tools-preview` to the CI toolchain; see `ci.yml`. THE GATE IS
TESTED: measured on the pinned toolchain (cargo-llvm-cov 0.9.0), a fixture
with every statement covered exits 0 at 100.00% TOTAL, and the same fixture
with one untested branch exits 1 at 0.00% TOTAL — the gate fails the build
under 95% (that is its acceptance test).

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
clean tree exits 0; two seeded identical functions fail:

```text
Found 1 clones.
Clone found (javascript):
 proof-dup-a.py[0,10] <-> proof-dup-b.py[0,10] (11 tokens, 100%)
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

## Trade-offs ("strict but staying usable")

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

## The init skill

`init-rust-repo/` initializes a new Rust repository with all of this. Install:
`scripts/install-skills.sh` (or copy the folder to `~/.agents/skills/`). The
templates are byte-identical copies — `scripts/verify-sync.sh` fails if they
drift.
