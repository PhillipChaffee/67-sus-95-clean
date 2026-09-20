# 🛡️ 67-sus-95-clean

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

## 🎁 What you get

Every folder ships the same guarantees:

- 🚦 A coverage gate that fails the build below 95%.
- 🏅 A free coverage badge on every build, red included.
- 🚫 Deny-level enforcement wherever the tool allows it.
- 🏷️ A reason attached to every enabled rule.
- 📚 Doc-comment substance enforced where a stable linter exists.
- 🧠 Cognitive complexity capped at 15.
- 📏 File length capped in effective lines, blanks and comments excluded.
- 📦 Unused dependencies, import layers, lockfiles, and TODOs gated per language.
- 📌 Pinned tool versions, and CI that matches the README.
- 🧾 Refusals documented with evidence, never silent.

## 🧭 How to use it

You are starting a new project in one of the five languages.

1. Read the folder for that language before you write code. Its README states
   what is enforced and why.
2. Install the skills with `scripts/install-skills.sh`. The script copies each
   folder's `init-<lang>-repo` skill into `~/.agents/skills/`.
3. Run the installed skill in your new repository. It writes the configuration
   files and the gate scripts.

## 🗂️ The languages

The table shows the code gates only. Details and reasoning live in each
folder's README.

| folder | lint | types | docs | size gates | coverage | formatter |
| --- | --- | --- | --- | --- | --- | --- |
| [`rust/`](rust/) | clippy: pedantic + nursery + cargo + picks | rustc: `missing_docs` deny | rustdoc: all 10 stable lints | `arborist` 15, cognitive-only. ≤ 1000 effective lines | `llvm-cov` ≥ 95% on lines, regions, functions | `rustfmt` |
| [`python/`](python/) | ruff: ALL, documented ignores | mypy `--strict` | ruff `D` (google) | `complexipy` 15, cognitive-only. ≤ 1000 effective lines | `pytest-cov` ≥ 95% (branch coverage) | `ruff format` |
| [`typescript/`](typescript/) | eslint: `strictTypeChecked` + jsdoc + sonarjs | tsc `strict` + 8 extras | jsdoc: require + check | sonarjs cognitive 15. `max-lines` ≤ 300 effective | vitest ≥ 95% (4 thresholds) | `prettier` |
| [`go/`](go/) | golangci-lint v2: strict extras | `go vet` + staticcheck | revive `exported` + godoclint | `gocognit` 15, cognitive-only. ≤ 750 effective lines | gate script ≥ 95% | `gofumpt` |
| [`shell/`](shell/) | shellcheck: default severity + two optional checks | refused: no shell type checker exists | ast-grep header-comment gate; prose checker refused | cognitive refused (omen probed, failed). ≤ 200 effective lines | gate script ≥ 95% (kcov) | `shfmt -d .` via `.editorconfig` |

## 🧼 The shared hygiene gates

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
Halstead, Maintainability Index, NPath. Refusals are documented in
`tasks/*/notes/`.

## 🗺️ Layout

| path | what it is |
| --- | --- |
| `<lang>/README.md` | what is enforced, and the trade-offs ("strict but staying usable") |
| `<lang>/<configs>` | the example configuration files, the set the gates read |
| `<lang>/init-<lang>-repo/` | the installable skill, plus `templates/` byte-copies so it is self-contained |
| `add-language/` | the skill that adds a new language to this repo |
| `scripts/verify-sync.sh` | fails when a template copy drifts from its canonical config |
| `scripts/install-skills.sh` | installs the skills into `~/.agents/skills/` |
| `tasks/*/notes/` | evidence-backed decision notes from the enforcement efforts: refusals and the parity audit |

## ➕ Adding a language

Run the `add-language` skill (see `add-language/SKILL.md`). The skill walks
the loop: research the language, author the folder, validate the gates. It
updates the list above. The invariant holds: a language folder is not merged
until its coverage gate provably fails a build below 95%.

## ⚖️ License

MIT. See [LICENSE](LICENSE).
