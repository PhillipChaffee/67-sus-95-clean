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

Cognitive complexity, nesting-depth caps, repeated literal to constant,
interface/class-size caps. Partial: TODO policy (FIX002 is still ignored).

## Rust-only gaps (no tool exists in the clippy/rustc stack)

Cognitive complexity, nesting depth, magic numbers, repeated literals,
class-size caps, commented-out code, import layers, cycles, SAST, test-style
lints, TODO gate, assertion-less tests. Partial: allow_attributes_without_reason
is not among the restriction picks. Coverage is line-only.

## Go-only gaps (linters exist in golangci-lint, not enabled)

cyclop, gocognit, funlen, nestif, mnd, goconst, interfacebloat, godox,
nolintlint, bidichk, gosec, depguard, gomodguard, thelper, testifylint,
tparallel. No commented-out-code checker fires today. Coverage is maxed at
statements (toolchain limit).

## TypeScript-only gaps (rules and plugins exist, not enabled)

eslint core: complexity, max-lines, max-statements, max-lines-per-function,
max-depth, max-params, no-magic-numbers. eslint-plugin-sonarjs: cognitive
complexity, no-duplicate-string, commented-out code (make sure that the plugin's rule
list). @vitest/eslint-plugin: expect-expect and test-style rules. knip: dead
code, unused deps, unused exports. dependency-cruiser: layers and cycles.
lockfile-lint. Partial: unused-disable-directive reporting is warn-only.
