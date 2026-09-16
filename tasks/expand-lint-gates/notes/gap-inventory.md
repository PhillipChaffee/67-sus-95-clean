# Note: gap inventory at the start of this epic

This is the state of the four language folders when the epic was planned.
Read the folder READMEs for the full detail. This file is the short version
that scopes the work.

## Covered everywhere already

Lint (strict surface), types (strict), docs and docstrings, formatter check,
coverage ≥ 95% machine-enforced, deny-not-warn, reasoned config only,
pinned toolchains.

## Repo-wide gaps (same tool for all four, nothing wired in)

Duplication (jscpd), secret scanning (gitleaks), dependency advisories
(osv-scanner), license compliance (osv-scanner --licenses), unused-dependency
detection (deptry / go mod tidy -diff / cargo-shear / knip), dead-file and
unused-export detection (vulture / knip), import-layer contracts
(import-linter / dependency-cruiser / depguard+gomodguard), mutation
testing (mutmut / cargo-mutants / StrykerJS), spell check (typos), link check
(lychee), markdown lint (markdownlint-cli2), artifact linting (shellcheck,
shfmt, actionlint, yamllint), lockfile integrity (pip hash-pinning,
lockfile-lint), dependency bans (cargo-deny / gomodguard_v2), commit-message
linting (commitlint, optional).

## Python-only gaps (no rule exists in the ruff/mypy stack)

Accepted after ws-02 (same list the python README's "Accepted gaps" section
carries): cognitive complexity, nesting-depth caps, repeated literal to
constant, interface/class-size caps. Assertion-less tests are covered by
the nightly mutmut score floor, not a separate gate. TODO policy is closed:
FIX002 is back ON and a TODO marker fails the build.

## Rust-only gaps (no tool exists in the clippy/rustc stack)

Accepted after ws-03 (same list the rust README's "Accepted gaps" section
carries): cognitive complexity, nesting-depth caps, magic-number detection,
repeated literal to constant, class-size caps, commented-out code detection,
SAST, test-style lints, assertion-less tests (covered by the nightly
cargo-mutants score floor), import-layer contracts. Cycles between crates
are already denied by cargo at the package boundary. Partial closed:
allow_attributes_without_reason is now among the restriction picks, and
coverage gates on lines, regions, and functions (not line-only).

## Go-only gaps (linters exist in golangci-lint, not enabled)

Accepted after ws-04 (same list the go README's "Accepted gaps" section
carries): commented-out-code detection (the gocritic commentedOutCode
checker exists but is experimental-tagged, which the config deliberately
leaves off), assertion-less tests, mutation testing (two tools with recent
activity — gremlins, avito-tech/go-mutesting — but neither with proven
score-floor gate semantics). All sixteen linters from the audit's list are
now enabled: the structural, hygiene/security, and test-style batches land
in .golangci.yml, plus go mod tidy -diff as the go-native unused-dependency
gate. The x/tools deadcode command was refused (reporter exit 0 on
findings; see ws-04-go/notes/decision-deadcode.md). Coverage remains
statements-only (toolchain limit).

## TypeScript-only gaps (rules and plugins exist, not enabled)

eslint core: complexity, max-lines, max-statements, max-lines-per-function,
max-depth, max-params, no-magic-numbers. eslint-plugin-sonarjs: cognitive
complexity, no-duplicate-string, commented-out code (make sure that the plugin's rule
list). @vitest/eslint-plugin: expect-expect and test-style rules. knip: dead
code, unused deps, unused exports. dependency-cruiser: layers and cycles.
lockfile-lint. Partial: unused-disable-directive reporting is warn-only.
