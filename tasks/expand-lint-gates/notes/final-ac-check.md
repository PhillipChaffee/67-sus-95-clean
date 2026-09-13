# Final acceptance-criteria check (as of this MR)

Met, with evidence:

- verify-sync.sh passes with every new pairing (run: bash
  scripts/verify-sync.sh; exit 0).
- Every ws-01 gate has a two-way proof and a measured wall time in each
  folder README: typos (0.02s), markdown lint (0.3s), link check (1.0s),
  secret scan (0.2s), duplication (0.04s), advisories plus licenses
  (seconds, seeded lockfile exit 1 and 130), artifact linting (0.2s).
- Every gate command is a labeled step in each folder ci.yml (a shared
  hygiene job with named steps) and in the local runner; the counts match
  (11 steps, 11 runner entries per folder).
- The local runner ships in all four folders and templates, with a smoke
  test recorded in the execution plan (one pass gate, one seeded fail gate,
  exit 1, per-gate lines).
- The repo itself is dogfooded: .github/workflows/hygiene.yml runs the same
  gates on the repo's own files.
- add-language now requires the new gate families and run-gates.sh; the
  commitlint decision is recorded (refused, with reasons).
- The refused metric families appear nowhere as gates.

Not met in this MR (remaining on the same branch):

- ws-02 through ws-05: the language-specific gates (python deptry/vulture/
  import-linter/hash-pinning/mutmut, rust cargo-deny/cargo-shear/
  suppression/coverage axes/mutants, go golangci-lint batches/tidy/deadcode,
  typescript eslint caps/sonarjs/vitest plugin/knip/dependency-cruiser/
  StrykerJS/bidi) are still to land as follow-up commits on this same MR
  branch, each with its own two-way proof and wall time.
- The mirror check: the canonical rule and all five mirrors now name the
  expanded baseline; a final byte-diff runs with the next batch.
- The runner's measured wall-time table is per gate; the runner itself
  still needs its final parity run once the language gates land.
