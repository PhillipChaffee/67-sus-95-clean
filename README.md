# 67-sus-95-clean

<p align="center">
  <img src="docs/meme.png" alt="Drake in landscape: turning away from 67% VIBES on the left, pointing at 95% CLEAN on the right" width="560">
</p>

One folder per language. Each folder holds the strictest workable enforcement
stack for that language: linting, type checking, doc-comment rules, size
gates, and a code-coverage gate at 95% minimum. "Strictest workable" means
the strict setup that stays usable day to day. Each folder ships the example
configuration files, a README that explains what every enforcement is for,
and an installable skill that initializes a new repository with the whole
setup.

## How to use it

You are starting a new project in one of the five languages.

1. Read the folder for that language before you write code. Its README states
   what is enforced and why.
2. Install the skills with `scripts/install-skills.sh`. The script copies each
   folder's `init-<lang>-repo` skill into `~/.agents/skills/`.
3. Run the installed skill in your new repository. It writes the configuration
   files and the gate scripts.

## The languages

The table shows the code gates only. Details and reasoning live in each
folder's README.

| folder | lint | types | docs | size gates | coverage | formatter |
| --- | --- | --- | --- | --- | --- | --- |
| [`rust/`](rust/) | clippy: pedantic + nursery + cargo + picks | rustc: `missing_docs` deny | rustdoc: all 10 stable lints | `arborist` 15, cognitive-only. ≤ 1000 effective lines | `llvm-cov` ≥ 95% on lines, regions, functions | `rustfmt` |
| [`python/`](python/) | ruff: ALL, documented ignores | mypy `--strict` | ruff `D` (google) | `complexipy` 15, cognitive-only. ≤ 1000 effective lines | `pytest-cov` ≥ 95% (branch coverage) | `ruff format` |
| [`typescript/`](typescript/) | eslint: `strictTypeChecked` + jsdoc + sonarjs | tsc `strict` + 8 extras | jsdoc: require + check | sonarjs cognitive 15. `max-lines` ≤ 300 effective | vitest ≥ 95% (4 thresholds) | `prettier` |
| [`go/`](go/) | golangci-lint v2: strict extras | `go vet` + staticcheck | revive `exported` + godoclint | `gocognit` 15, cognitive-only. ≤ 750 effective lines | gate script ≥ 95% | `gofumpt` |
| [`shell/`](shell/) | shellcheck: default severity + two optional checks | refused: no shell type checker exists | ast-grep header-comment gate; prose checker refused | cognitive refused (omen probed, failed). ≤ 200 effective lines | gate script ≥ 95% (kcov) | `shfmt -d .` via `.editorconfig` |

## The shared hygiene gates

Every folder also runs hygiene and supply-chain gates beside the code gates.
The shared set:

- a spell check and a markdown lint
- a secret scan and a link check
- copy-paste detection
- lint of the repo's own artifacts (shellcheck, shfmt, yamllint, actionlint)
- dependency advisories and license checks

All tools are pinned, and each gate carries a recorded proof that it fails on
demand. You run the same gates locally with the folder's `run-gates.sh`. The
per-language extras (deptry, vulture, cargo-deny, knip, `go mod tidy -diff`,
and the rest) are documented in the folder READMEs. shell is the exception on
advisories and licenses because it carries no lockfile manifest.

Mutation testing runs nightly where it is wired (mutmut for python,
cargo-mutants for rust) with recorded score floors. Some metric families are
refused after measurement, and no config gates them: coupling dashboards,
Halstead, Maintainability Index, NPath.

## House rules

1. The coverage gate fails the build below 95%. Each folder wires it with its
   own tool: llvm-cov, pytest-cov, vitest, or a gate script for go and shell.
2. Every rule enabled by hand carries its reason in the config or the README.
   A rule without a reason is deleted at the next review.
3. The configs use deny where the tool allows it. Where a CI wrapper makes
   warnings fatal anyway, the config uses warn, and the folder README
   documents the case.
4. A comment or docstring that only restates the signature is a bug. A stable
   linter enforces comment content where one exists: ruff D,
   eslint-plugin-jsdoc, revive `exported`, and the rustdoc and clippy doc
   lints. Where no stable checker exists, the folder README records the
   policy for the human reviewer.
5. Tool versions are pinned (`rust-toolchain.toml`, `python_version`,
   `engines`, `run.go`). Nightly-only options are marked as such. CI runs
   exactly the commands in the README.
6. Every folder's CI ships its coverage report to
   [Coveralls](https://coveralls.io) with `coverallsapp/github-action@v2`.
   The action is free for public repositories on the built-in `GITHUB_TOKEN`,
   so it needs no account and no secret. The report is written before the
   gate runs and is uploaded even when the build fails, so red builds still
   get the badge.
7. Each language's own tool gates its unused dependencies, its import layers,
   its lockfile integrity, and its TODO markers. The tools are deptry
   (python), `go mod tidy -diff` (go), cargo-shear (rust), and knip
   (typescript) for unused dependencies, import-linter and dependency-cruiser
   for import layers, and hash-pinned installs and lockfile-lint for lockfile
   integrity. A TODO marker fails the build in every stack: ruff FIX002,
   godox, no-warning-comments, a rust grep. Where the pinned tools cannot
   tell the truth, the refusal is recorded in `tasks/*/notes/` (StrykerJS
   with vitest 5, x/tools deadcode).
8. Complexity is cognitive-only, file length counts effective lines, and doc
   substance is gated where a mechanical check exists. Cognitive complexity
   is capped at 15, Sonar's own default (gocognit, complexipy, arborist,
   sonarjs). The shell candidate was probed and refused, and cyclomatic is
   removed everywhere. The file-length caps are per language, from 750 (go)
   to 200 (shell). Every refusal is documented in
   `tasks/enforce-gates/notes/`.

## Layout

| path | what it is |
| --- | --- |
| `<lang>/README.md` | what is enforced, and the trade-offs ("strict but staying usable") |
| `<lang>/<configs>` | the example configuration files, the set the gates read |
| `<lang>/init-<lang>-repo/` | the installable skill, plus `templates/` byte-copies so it is self-contained |
| `add-language/` | the skill that adds a new language to this repo |
| `scripts/verify-sync.sh` | fails when a template copy drifts from its canonical config |
| `scripts/install-skills.sh` | installs the skills into `~/.agents/skills/` |
| `tasks/*/notes/` | evidence-backed decision notes from the enforcement efforts: refusals and the parity audit |

## Adding a language

Run the `add-language` skill (see `add-language/SKILL.md`). The skill walks
the loop: research the language, author the folder, validate the gates. It
updates the list above. The invariant holds: a language folder is not merged
until its coverage gate provably fails a build below 95%.

## License

MIT. See [LICENSE](LICENSE).
