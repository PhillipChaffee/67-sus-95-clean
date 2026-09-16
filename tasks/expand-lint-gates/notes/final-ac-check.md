# Final acceptance-criteria check — every epic and workstream box

Recorded 2026-09-15, on branch `phillip/expand-lint-gates-execution`. Each
box is met with the proving command or README pointer. "Met" means checked
against the finished work, not against intent.

## Epic spec — UX acceptance criteria

- [x] One labeled CI job (step) per gate, name tells the gate. Evidence:
  every gate step carries its tool and version (`Spell check (typos
  v1.50.1)`, `RustSec advisories (cargo-deny v0.20.2)`, `Dependency hygiene
  (knip v6.35.1)`, …); the runner↔CI parity lines in the four folder
  READMEs record the count match (python 19↔19, rust 21↔21, go 19↔19,
  typescript 19↔19).
- [x] Each gate failure points at the README section. Every CI step name has
  a folder README section (checked mechanically with name → section grep;
  the three cargo-deny checks share one section titled "Hygiene —
  supply-chain policy (cargo-deny…)", the depcruiser gate's section is
  "Architecture — import layers and cycles (dependency-cruiser)").
- [x] One local command gives the CI verdict: `./run-gates.sh` in all four
  folders runs the PR-blocking gates in parallel, prints one PASS/FAIL line
  per gate, exits nonzero on failure. Smoke test re-run on the current
  runner logic: two fake gates → `PASS passing`, `FAIL failing`, exit 1.
- [x] An init skill produces the full gate set: every init skill's copy list
  now carries every template (verified against `scripts/verify-sync.sh`
  pairings; the scratch template-copy check produced ci.yml gate-step
  counts python 22, rust 23, go 22, typescript 22, and `.github/workflows/`
  with ci.yml + mutation.yml where the folder ships a nightly mutation
  workflow). The skills' copy lists were completed in this sweep (commit
  "Complete the init skills' template copy lists").
- [x] Root README and docs/index.html show the new gates. Grep check run:
  every audit gate name appears in both (typos, gitleaks, jscpd,
  osv-scanner, deptry, vulture, import-linter, mutmut, cargo-deny,
  cargo-shear, cargo-mutants, knip, dependency-cruiser, lockfile,
  hash-pinned, sonarjs, go mod tidy). The rendered page is saved as
  `notes/index-rendered-fixture.html`.

## Epic spec — UX negatives

- [x] No disabled new gate without a reason: every config entry carries its
  reason inline (ruff ignore list, Cargo.toml.example picks, .golangci.yml
  per-linter comments, eslint.config.mjs rule comments — all written during
  the tasks and reviewed in the READMEs).
- [x] No warn-only gate: every gate's seeded-violation proof records a
  nonzero exit in the folder README (the gate-contract both-way proofs).
  cargo-shear and eslint unused-directive reporting were escalated with
  `--deny-warnings` / `reportUnusedDisableDirectives: "error"`.

## Epic spec — technical acceptance criteria

- [x] Every new gate: pinned version in README, config file, CI step running
  the README command, green + seeded-failure outputs recorded in the README
  (per-gate sections in the four folder READMEs, same style as the coverage
  proofs).
- [x] `scripts/verify-sync.sh` pairs every new canonical config with a
  byte-identical template copy: `bash scripts/verify-sync.sh` exits 0 with
  the full pairing list (including osv-scanner.toml, mutation.yml, knip
  .jsonc, .dependency-cruiser.cjs, lockfile and requirements files).
- [x] The repo's own CI runs the hygiene gates on itself:
  `.github/workflows/hygiene.yml` (typos through actionlint plus the
  python lockfile-integrity step), and it passes locally.
- [x] Each workstream spec has mechanically checkable positive and negative
  ACs (present in all six spec files).
- [x] Each folder ships `run-gates.sh` (template-copied, paired) matching
  its ci.yml step list; per-gate wall times recorded in each folder README.

## Epic spec — technical negatives

- [x] No gate ships without a failure proof (each README section carries the
  seeded-failure output; the two refused gates record the evidence instead).
- [x] No warn-only gate (same proofs).
- [x] No refused metric as a gate: grep over all config/CI/runner files for
  LCOM/Halstead/MI/NPath finds only `pythonpath` (a pytest key containing
  the substring "npath") — no refused metric anywhere.
- [x] No gate for a language without a maintained tool: mutation testing in
  go and typescript and go deadcode are documented accepted gaps/refusals
  (`ws-04-go/notes/decision-deadcode.md`,
  `ws-05-typescript/notes/decision-stryker.md`, plus the folder READMEs'
  accepted-gaps sections).
- [x] No PR-blocking gate runs only in CI: the scheduled-only set is exactly
  python `mutation.yml` and rust `mutation.yml` (cron present in both); the
  folder runners' headers say the mutation gate runs on a schedule.

## Workstream ACs (spot-walk with evidence)

ws-01 (repo-wide): all seven tasks landed with both-way proofs and wall
times in every folder README; commitlint decision recorded (refused);
verify-sync pairings pass; the root dogfood workflow runs the same gates.

ws-02 (python): deptry, vulture, import-linter, TODO policy (FIX002 back
on), hash-pinned lockfile (with osv-scanner license overrides for vulture
and libcst), mutmut nightly (floor 85, both-way proof, mutation.yml +
template + pairing), accepted-gaps section matches the epic gap inventory.

ws-03 (rust): cargo-deny three-check gate with fail-closed proof (offline +
empty DB exits 1), cargo-shear both ways, allow_attributes_without_reason
pick proven under pinned clippy 1.98.0, TODO grep gate, coverage gate
strengthened to lines+regions+functions at 95 (proven failing on a seeded
untested function at 86.36/75.00/86.36), cargo-mutants nightly (floor 85
from outcomes.json; clean 19/21 = 90% passes, seeded 19/26 = 73% fails),
accepted-gaps section written.

ws-04 (go): structural batch (cyclop 10, gocognit 30, funlen 60/40, nestif
5, mnd, goconst 3, interfacebloat 10 — all seven proven firing), hygiene
and security batch (godox, nolintlint, bidichk, gosec, depguard,
gomodguard_v2 — all six proven firing), test-style batch (thelper,
testifylint, tparallel — all three proven firing), `go mod tidy -diff`
gate both ways, x/tools deadcode refused with scratch-run evidence
(`ws-04-go/notes/decision-deadcode.md`; exit 0 on findings at v0.40.0 and
v0.50.0), accepted-gaps section written after re-checking gocritic's
commentedOutCode (exists, experimental-tagged) and the go mutation tools
(gremlins, avito go-mutesting — no proven score-floor gate).

ws-05 (typescript): six eslint core metric caps + stale-directive
escalation proven both ways, sonarjs slice (S3776, S1192, S125 — all three
fire) with the no-magic-numbers cap and the tests carve-out, vitest plugin
slice proven, knip + lockfile-lint proven both ways, dependency-cruiser
proven both ways, bidi grep gate proven (clean passes, seeded zero-width
space fails, accented+emoji passes), StrykerJS refused with scratch-run
evidence (`ws-05-typescript/notes/decision-stryker.md`; 32/32 mutants
survive at the latest released pins, upstream #6210/#6146/#6213/#6209
open, fix #6214 unmerged), accepted-gaps section matches the inventory.

ws-06: root README table + house rule 8 + docs/index.html mirror (this
sweep), harness rule mirrors updated with a 12-line goose bound
(`ws-06-contracts-and-docs/notes/mirrors.md`), runner↔CI parity recorded
per folder, this file.

## Residual notes

- The typescript folder's local lint runs need `npm install
  --legacy-peer-deps` on npm 11.4.2 (its arborist cannot build the ideal
  tree from vitest 5's peer chain); CI uses `npm ci` from the generated
  lockfile and is unaffected. Recorded here because it shaped the fixture
  work.
- The go folder's `deadcode` investigation refused the tool (reporter exit
  0), and the typescript folder refused StrykerJS at this pin; both carry
  their evidence notes and are named as accepted gaps in the folder
  READMEs.
