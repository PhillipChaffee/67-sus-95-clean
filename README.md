# 67-sus-95-clean

<p align="center">
  <img src="docs/meme.png" alt="Drake in landscape: turning away from 67% VIBES on the left, pointing at 95% CLEAN on the right" width="560">
</p>

One folder per language carrying the **strictest workable** enforcement stack for
that language: linting, type checking, comment and docstring rules, and a
**code-coverage gate at ≥ 95% in every folder**. Each language folder
ships the example configuration files, a README that explains what each
enforcement is for, and an installable AI skill that initializes a new
repository in that language with the whole setup.

Use it as a reference: when you start a new project in a language, read its
folder, or install its skill and run it in the new project, and you start from
the strict baseline instead of assembling it from memory.

## Layout

| path | what it is |
| --- | --- |
| `<lang>/README.md` | what is enforced and the trade-offs ("strict but staying usable") |
| `<lang>/<configs>` | the canonical example configs (the enforcement surface) |
| `<lang>/init-<lang>-repo/` | the AI skill, plus `templates/` byte-copies so it is self-contained |
| `add-language/` | skill that adds a NEW language to this repo |
| `scripts/*.sh` | `verify-sync.sh` catches template drift; `install-skills.sh` installs the skills |
| `tasks/expand-lint-gates/notes/` | the epic's evidence-backed decision notes: refused metric families, the go deadcode and typescript StrykerJS refusals |

## Languages

Details and reasoning live in each folder's README; the shape:

| folder | lint | types | docs | coverage | formatter | hygiene + supply-chain |
| --- | --- | --- | --- | --- | --- | --- |
| [`rust/`](rust/) | clippy: pedantic + nursery + cargo + picks; rustdoc group deny; `allow_attributes_without_reason` | rustc: `missing_docs` deny | rustdoc: all 10 stable lints | `llvm-cov` ≥ 95% on lines, regions, and functions | `rustfmt` | typos, gitleaks, jscpd, osv-scanner advisories + licenses, cargo-deny (RustSec, license policy, bans + duplicates), cargo-shear, TODO grep, artifact linting; `cargo-mutants` nightly |
| [`python/`](python/) | ruff: ALL, documented ignores; TODO marker banned | mypy `--strict` | ruff `D` (google) | `pytest-cov` ≥ 95% | `ruff format` | typos, gitleaks, jscpd, osv-scanner advisories + licenses, deptry, vulture, import-linter, hash-pinned lockfile, artifact linting; `mutmut` nightly |
| [`typescript/`](typescript/) | eslint: `strictTypeChecked` + jsdoc + metric caps + sonarjs + vitest plugin | tsc `strict` + 8 extras | jsdoc: require + check | vitest ≥ 95% ×4 | `prettier` | typos, gitleaks, jscpd, osv-scanner advisories + licenses, knip, lockfile-lint, dependency-cruiser, bidi grep, artifact linting |
| [`go/`](go/) | golangci-lint v2: strict extras (size caps, hygiene, security, test-style) | `go vet` + staticcheck | revive `exported` | gate script ≥ 95% | `gofumpt` | typos, gitleaks, jscpd, osv-scanner advisories + licenses, `go mod tidy -diff`, artifact linting |

(The full commands — `cargo llvm-cov --fail-under-lines 95`, `fail_under = 95` with branch coverage, vitest's four thresholds, the go `coverage-gate.sh` — are in the folders. Mutation testing runs nightly where it is wired (python mutmut, rust cargo-mutants) with recorded score floors; where it is refused, the refusal carries the scratch-run evidence. Nothing here offers the refused families — coupling dashboards, Halstead/MI/NPath — as gates.)

## The house rules every folder shares

1. **Coverage ≥ 95%, enforced by the machine**, not by aspiration: each gate
   fails the build under its threshold (llvm-cov `--fail-under-lines` /
   `fail_under = 95` / vitest `thresholds` / the go cover-func total check).
2. **Every lint level and every rule enabled by hand carries its reason** in
   the config or the README. A rule without a why gets deleted on the next
   review.
3. **Deny, not warn** where the tool allows it; `warn`-only where the language's
   CI wrapper makes warnings fatal anyway (documented in each folder).
4. **Comments and docstrings that only restate the signature are the bug.**
   Content rules philosophy is documented per folder; machine enforcement is
   enabled where a stable linter exists (ruff D, eslint-plugin-jsdoc, revive
   `exported`, rustdoc/clippy doc lints) and documented as human policy where
   no stable checker exists.
5. **Determinism**: pinned toolchain versions (`rust-toolchain.toml`,
   `python_version`, `engines`/TS version, `run.go`), nightly-only options
   marked as such, CI running exactly the local commands in the READMEs.
6. **Coverage reports are free badges, not private CLI artifacts**: every
   folder's CI ships its report to [Coveralls](https://coveralls.io)
   (`coverallsapp/github-action@v2`, free for public repositories on the
   built-in `GITHUB_TOKEN` — no account, no secret), so a repository built
   from a folder gets a free coverage badge, red builds included — the
   report is written before the gate is evaluated, and uploaded even when
   the build fails.

7. **Hygiene and supply-chain gates run beside the code gates**: every
   folder's CI carries a spell check, secret scan, copy-paste detection,
   markdown lint, link check, own-artifact linting (shellcheck, shfmt,
   yamllint, actionlint), and dependency advisories plus license gates —
   all pinned, all with recorded two-way proofs, and all runnable locally
   through each folder's `run-gates.sh` (see the hygiene sections in the
   folder READMEs).
8. **Unused dependencies, layer contracts, lockfile integrity, and TODO
   markers are gated per language by the language's own tool**: deptry /
   `go mod tidy -diff` / cargo-shear / knip for unused dependencies;
   import-linter / dependency-cruiser / depguard for import layers;
   hash-pinned installs (python) and lockfile-lint (TypeScript) for
   lockfile integrity; a TODO marker fails the build in every stack (ruff
   FIX002, godox, no-warning-comments, a rust grep). Mutation testing
   where it is wired (mutmut and cargo-mutants nightly, with recorded
   score floors) and recorded refusals where the pinned tools cannot tell
   the truth (StrykerJS with vitest 5, x/tools deadcode).

## Adding a language

Run the `add-language` skill (see `add-language/SKILL.md`), which walks the
research → author → validate loop and updates this list. The invariant it must
keep: a language folder is not merged until its coverage gate provably fails a
build under 95%.

## License

MIT — see [LICENSE](LICENSE).
