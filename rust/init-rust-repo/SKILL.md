---
name: init-rust-repo
description: >-
  Initializes a new Rust repository with the strictest workable enforcement stack:
  clippy pedantic/nursery/cargo plus restriction picks as workspace lints, the
  rustdoc stable group denied, missing_docs denied, a pinned rust-toolchain.toml,
  a CI workflow running lint/type/doc/coverage gates, and cargo llvm-cov enforced
  at >=95% line coverage with a tested fail-under gate. Use when the user asks to
  initialize, bootstrap, or set up a new Rust project or repository with strict
  linting, documentation enforcement, and a code-coverage gate.
---

# Initialize a strict Rust repository

Sets up a brand-new Rust repository so that `cargo check` fails on any
undocumented public item, `cargo doc` fails on any broken doc link, clippy's
strict groups/lints run as errors in CI, and `cargo llvm-cov
--fail-under-lines 95` fails the build below 95% line coverage. Read this
repo's `rust/README.md` for the reasoning behind every piece; the steps below
assume that reasoning and only record the work.

# Preconditions

- A `cargo`-capable Rust installation (rustup honored by `rust-toolchain.toml`
  applies automatically).
- You know the target directory and the package (or workspace) name.

# Steps

1. Create the repository: `cargo init <name>` (or `cargo init --lib <name>`
   for a library), then `git init` if cargo has not already done so.
2. Copy every template from this skill's `templates/` directory into the new
   repository root:
   `Cargo.toml.example -> Cargo.toml.example` (leave beside the generated
   Cargo.toml), `clippy.toml -> clippy.toml`,
   `rust-toolchain.toml -> rust-toolchain.toml`,
   `rustfmt.toml -> rustfmt.toml`, `ci.yml -> .github/workflows/ci.yml`,
   `AGENTS.md.example -> AGENTS.md`.
   Use the contents of `Cargo.toml.example` to merge its `[workspace.lints]`
   table into the new `Cargo.toml` (do not overwrite the generated `[package]`
   block; keep the `[lints] workspace = true` wiring from the example), and
   keep `Cargo.toml.example` as documentation of the table's shape.
3. Merge the comment rules from `AGENTS.md.example` into the new repo's
   `AGENTS.md` as its "Comment and doc-comment rules" section (adapt the
   last rule's domain mention to the project's).
4. `rustup component add llvm-tools-preview` (first coverage run needs it;
   rust-toolchain.toml also requests it).
5. Run every gate and make each one pass or fail for a known, acceptable
   reason:
   - `cargo fmt --all -- --check`
   - `cargo clippy --workspace --all-targets -- -D warnings`
   - `RUSTDOCFLAGS='-D warnings' cargo doc --workspace --no-deps`
   - `cargo test --workspace`
   - `cargo llvm-cov --workspace --fail-under-lines 95`
   `missing_docs = "deny"` means an undocumented pub item FAILS the build;
   write the doc or scope a `#[expect(missing_docs, reason = "...")]` —
   never delete the lint to pass the build.
6. Edit the restriction picks in `[workspace.lints.clippy]` to the failure
   modes this project actually has, one reason per pick; the template ships
   the crash-and-printer picks common to shipped binaries.
7. Wire the free coverage badge: the `ci.yml` template already uploads
   `lcov.info` to Coveralls (the coverallsapp action runs on the built-in GITHUB_TOKEN, free for a public repo).
   Add to the new repository's README:
   `![coverage](https://coveralls.io/github/OWNER/REPO/badge.svg?branch=main)`
   with OWNER/REPO replaced by the GitHub slug, after the first push. No repository secret is needed; for a private repo the owner would
   add a Coveralls repo token instead.
8. Commit everything in one bootstrap commit (message style is the repo's
   choice from here on).

# Gates

- After step 5, ALL five commands run green (or a documented, pre-existing
  decision explains any red).
- `scripts/verify-sync.sh` in this reference repo still passes: templates
  must be edits of the canonical files, not independent forks.
- If step 5's coverage command cannot run (no llvm-tools, or a crate cannot
  be instrumented), STOP and report the tooling failure; do not proceed with
  the gate quietly missing.
