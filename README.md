# 67-sus-95-clean

<p align="center">
  <img src="https://api.memegen.link/images/drake/67~p_vibes/95~p_clean.png" alt="Drake: reject 67% vibes; approve 95% clean" width="360">
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
|---|---|
| `<lang>/README.md` | what each enforced thing is, and the trade-offs ("strict but staying usable") |
| `<lang>/<configs>` | the canonical example configs (the enforcement surface) |
| `<lang>/init-<lang>-repo/SKILL.md` | the AI skill: copy the folder into `~/.agents/skills/` and run it in a new directory |
| `<lang>/init-<lang>-repo/templates/` | byte-duplicates of the canonical configs, so the skill is self-contained |
| `add-language/` | skill that adds a NEW language to this repo |
| `scripts/verify-sync.sh` | fails when a `templates/` copy drifts from its canonical file |
| `scripts/install-skills.sh` | installs the `init-*` and `add-language` skills |

## Languages

| folder | lint | types | docs | coverage | formatter |
|---|---|---|---|---|---|
| [`rust/`](rust/) | clippy (pedantic, nursery, cargo, restriction picks) + `rustdoc` group deny | rustc (`missing_docs` deny) | `[workspace.lints.rustdoc] all = deny`, rustdoc lints | `cargo llvm-cov --fail-under-lines 95` | `rustfmt` |
| [`python/`](python/) | ruff (ALL minus documented ignores) | mypy `--strict` + beyond | ruff `D` (google) | `pytest-cov` `fail_under = 95`, branch coverage | `ruff format` |
| [`typescript/`](typescript/) | eslint + typescript-eslint `strict-type-checked` | tsc `strict` + 8 beyond-strict flags | eslint-plugin-jsdoc (require & check) | vitest coverage thresholds 95 | prettier |
| [`go/`](go/) | golangci-lint v2 (standard + strict extras) | `go vet` + staticcheck | revive `exported` | `go tool cover -func` ≥ 95 gate | `gofumpt` |

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
   folder's CI ships its report to [Codecov](https://about.codecov.io)
   (`codecov-action@v7`, free for public repositories, tokenless by default
   for them), so a repository built from a folder gets a free coverage badge,
   red builds included — the report is written before the gate is evaluated,
   and uploaded even when the build fails.

## Adding a language

Run the `add-language` skill (see `add-language/SKILL.md`), which walks the
research → author → validate loop and updates this list. The invariant it must
keep: a language folder is not merged until its coverage gate provably fails a
build under 95%.

## License

MIT — see [LICENSE](LICENSE). The site lives at
https://phillipchaffee.github.io/67-sus-95-clean/ (`docs/index.html`).
