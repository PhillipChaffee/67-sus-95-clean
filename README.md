# 🛡️ full-lint

One folder per language — the strictest setup that stays usable.

## 🎁 What you get

Every folder ships:

- 🚦 **Coverage gate** — fails below 95%.
  - ✅ Free badge.
- 🧹 **Linting + type checking** — the language's strictest:
  - 🚫 Deny-level wherever the tool allows.
  - 🏷️ Reason on every rule.
  - 📚 Doc comment substance.
  - 🧠 Cognitive complexity ≤ 15.
  - 📏 File length.
  - 📦 Unused deps, import layers, lockfiles, TODOs.
- 📌 **Pinned tools** — CI matches the README.
- 🧾 **Refusals** — evidence-backed, never silent.

## 🧭 How to use it

Starting a new project in one of the five languages:

1. Read the folder's README first — it states what is enforced, and why.
2. Install the skills: `scripts/install-skills.sh` copies each
   `init-<lang>-repo` skill into `~/.agents/skills/`.
3. Run the skill in your new repo — it writes the configs and the gate
   scripts.

## 🗂️ The languages

Code gates only — details and reasoning live in each folder's README.

| folder | lint | types | docs | size gates | coverage | formatter |
| --- | --- | --- | --- | --- | --- | --- |
| [`rust/`](rust/) | clippy: pedantic + nursery + cargo + picks | rustc: `missing_docs` deny | rustdoc: all 10 stable lints | `arborist` 15, cognitive-only. ≤ 1000 effective lines | `llvm-cov` ≥ 95% on lines, regions, functions | `rustfmt` |
| [`python/`](python/) | ruff: ALL, documented ignores | mypy `--strict` | ruff `D` (google) | `complexipy` 15, cognitive-only. ≤ 1000 effective lines | `pytest-cov` ≥ 95% (branch coverage) | `ruff format` |
| [`typescript/`](typescript/) | eslint: `strictTypeChecked` + jsdoc + sonarjs | tsc `strict` + 8 extras | jsdoc: require + check | sonarjs cognitive 15. `max-lines` ≤ 300 effective | vitest ≥ 95% (4 thresholds) | `prettier` |
| [`go/`](go/) | golangci-lint v2: strict extras | `go vet` + staticcheck | revive `exported` + godoclint | `gocognit` 15, cognitive-only. ≤ 750 effective lines | gate script ≥ 95% | `gofumpt` |
| [`shell/`](shell/) | shellcheck: default severity + two optional checks | refused: no shell type checker exists | ast-grep header-comment gate; prose checker refused | cognitive refused (omen probed, failed). ≤ 200 effective lines | gate script ≥ 95% (kcov) | `shfmt -d .` via `.editorconfig` |

## 🧼 The shared hygiene gates

Beside the code gates, every folder runs the shared hygiene set:

- spell check + markdown lint
- secret scan + link check
- copy-paste detection
- own-artifact lint (shellcheck, shfmt, yamllint, actionlint)
- dependency advisories + licenses

All pinned, each with a recorded proof it fails on demand. Run them locally:
the folder's `run-gates.sh`. Per-language extras — deptry, vulture,
cargo-deny, knip, `go mod tidy -diff`, the rest — live in the folder
READMEs. shell skips advisories + licenses: no lockfile manifest.

Mutation testing runs nightly where wired (mutmut for python, cargo-mutants
for rust), score floors recorded. Refused after measurement, never gated:
coupling dashboards, Halstead, Maintainability Index, NPath. Refusals in
`tasks/*/notes/`.

## 🗺️ Layout

| path | what it is |
| --- | --- |
| `<lang>/README.md` | what is enforced, and the trade-offs |
| `<lang>/<configs>` | the configs the gates read |
| `<lang>/init-<lang>-repo/` | the installable skill, with `templates/` byte-copies |
| `add-language/` | the skill that adds a language |
| `scripts/verify-sync.sh` | fails on template drift |
| `scripts/install-skills.sh` | installs the skills |
| `tasks/*/notes/` | refusal and parity-audit notes |

## ➕ Adding a language

Run the `add-language` skill (`add-language/SKILL.md`): research the
language, author the folder, validate the gates. It updates the table above.
The invariant: no folder merges until its coverage gate provably fails a
build below 95%.

## ⚖️ License

MIT. See [LICENSE](LICENSE).
