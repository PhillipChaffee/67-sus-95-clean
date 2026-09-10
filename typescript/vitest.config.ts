// The coverage gate: vitest runs the suite (test files in src, beside their
// sources) and fails the build under 95% on any of the four axes. All keys
// here are verified against the vitest 5 coverage config reference.
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    include: ["src/**/*.test.ts"], // Tests live beside their sources; `include` narrowed from the default so `node_modules` never houses a stray test runner target
    coverage: {
      enabled: true, // `npm test` never runs without the gate
      provider: "v8", // Default provider; speeds over istanbul with equivalent accuracy since vitest's ast-aware v8 remapping
      include: ["src/**/*.{ts,tsx}"], // Default is only-imported-files; naming src puts never-imported sources in the report too (they count as uncovered, which is the point)
      exclude: ["**/*.test.ts"], // Tests pad their own axis; the gate measures shipped code, not its harness
      thresholds: {
        lines: 95, // Fails under 95% line coverage
        functions: 95, // Fails under 95% function coverage
        branches: 95, // Fails under 95% branch coverage
        statements: 95, // Fails under 95% statement coverage
      }, // global aggregation is vitest's default; per-file gates are opt-in via `thresholds.perFile` and left off here
      reporter: ["text", "lcov"], // lcov lands at coverage/lcov.info for the Coveralls upload; text stays in the run log
      reportOnFailure: true, // a red build still uploads its real, red coverage rather than going badge-less
    },
  },
});
