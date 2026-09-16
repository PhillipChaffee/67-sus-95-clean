# Decision: refuse the StrykerJS mutation gate (typescript) at this pin

Tested empirically, not from docs. Environment: @stryker-mutator/core
10.0.0 + @stryker-mutator/vitest-runner 10.0.0 (both the latest releases)
against the template's pinned vitest 5.0.0.

Scratch runs on the template fixture (3 tests, 32 mutants in src/lib.ts):

- `npx stryker run` with default config: 32/32 mutants survive, score 0.00,
  exit 1. Even the mutant `return left + right` -> `return left - right`
  survives while the test asserts `add(2, 3) === 5`, and the dry run
  reports all 3 tests passing.
- With `coverageAnalysis: "all"` (bypassing the broken per-test filter):
  same result, 32/32 survive.

Upstream evidence, all open at v10.0.0 (latest release, 2026-08-14):

- stryker-js#6210: on Vitest 5 the per-test name filter matches nothing, so
  every covered mutant survives (testNamePattern now joins with " > ").
- stryker-js#6146: mutants that executed zero tests are reported as
  Survived.
- stryker-js#6213: mutants with testsCompleted: 0 reported as Survived at
  low worker counts.
- stryker-js#6209: static mutants falsely Survived; reloadEnvironment
  capability declared but not implemented.
- Fix PR stryker-js#6214: not merged; no release ships it.

The gate cannot produce a truthful verdict at any released pin with
vitest 5: the verdicts are wrong in the dangerous direction (survive).
A scheduled job that always reads 0% or always passes would both be lies.
Refused per the gate contract; no wrapper script substitutes for correct
verdicts.

TypeScript mutation testing stays an accepted gap (see the README
trade-offs). What changes the answer: a stryker release containing #6214
that verifies against vitest 5.
