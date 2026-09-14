# Execution plan — expand-lint-gates

This is the step-by-step build plan for the epic. It turns the workstream
tasks into commits. Parallel chunks each get their own commit, because they
touch disjoint files. Follow the owner's plan-steps contract: branch setup,
acceptance criteria, commit organization, per-commit checks, verify, final
checks, pre-MR checklist, push and MRs.

## Branch setup

One base branch for the foundation tranche:

- `phillip/expand-lint-gates-execution`, cut from `main`.

For the parallel build phases (phases 3 and 4), each workstream gets its own
branch and its own git worktree, so several agents can work at the same time
without touching each other's files:

- `phillip/expand-lint-gates-ws01-repo-wide`
- `phillip/expand-lint-gates-ws02-python`
- `phillip/expand-lint-gates-ws03-rust`
- `phillip/expand-lint-gates-ws04-go`
- `phillip/expand-lint-gates-ws05-typescript`
- `phillip/expand-lint-gates-ws06-contracts`

Merge order: ws-01 first, then ws-02..ws-05 (any order), then ws-06.

## Acceptance criteria (execution level)

Positive:

- [ ] Each phase lands as commits, one commit per parallel chunk, and each
      commit passes the per-commit checks (verify-sync.sh, bash -n on every
      new script, and a runner smoke test for commit-phase scripts).
- [ ] Every gate task ends with a recorded two-sided proof in the folder
      README before its commit lands (the gate contract).
- [ ] The local runner exists in all four folders, and its gate list matches
      the CI steps (recorded diff check).
- [ ] Each new gate task records the measured wall time of its command in
      the folder README.

Negative:

- [ ] No commit claims a gate without its both-way proof.
- [ ] No commit touches a file another open lane is editing (workstream
      lanes are file-disjoint by design).
- [ ] Nothing is pushed and no MR opens without the ticket id from the
      owner.

## Commit organization

### Phase 1: foundation (execute now, no external tools needed)

Four independent lanes, one commit each:

| lane | commit | files |
| --- | --- | --- |
| 1 | Record the doc drift fixes the audit found | go/README.md, rust/Cargo.toml.example + template, typescript/README.md |
| 2 | Add the expand-lint-gates epic plan | tasks/expand-lint-gates/** |
| 3 | Require the new gate families in add-language | add-language/SKILL.md |
| 4 | Add the local parallel gate runner | 4x run-gates.sh + templates + README Commands lines + verify-sync pairings |

Phase-1 acceptance:

- [ ] verify-sync.sh passes with the four new runner pairings.
- [ ] Every run-gates.sh passes bash -n and a /tmp smoke test (a fake gate
      list: one passing gate, one failing gate; exit code 1; one line per
      gate).
- [ ] add-language edits are additive only (existing headings and steps
      unchanged).

### Phase 2: ws-01 repo-wide gates (7 commits, in task order)

Each task = one commit. Gate order: T01 typos, T02 markdown + links, T03
gitleaks, T04 jscpd, T05 osv-scanner, T06 artifact linting, T07 commitlint
decision.

Install prerequisite (once, before the phase):

```bash
brew install typos gitleaks shellcheck shfmt yamllint actionlint osv-scanner
npm install -g markdownlint-cli2 jscpd
```

Per-commit recipe (every task follows it): pin the tool from official docs,
write the root config with reasons, add the labeled CI job to all four
folder ci.yml files plus template copies, add the README sections, record
the both-way proof, add the runner entry, record the wall time, run
verify-sync.sh, commit.

### Phase 3: language workstreams (parallel branches, one commit per task)

Run ws-02..ws-05 concurrently, one worktree per workstream. Inside a
workstream, tasks land in the listed order (shared README and ci.yml files).
Each task = one commit:

- ws-02 python: deptry, vulture, import-linter, TODO policy, hash-pinned
  installs, mutmut, gap docs
- ws-03 rust: cargo-deny, cargo-shear, suppression + TODO, coverage axes,
  cargo-mutants, gap documentation
- ws-04 go: structural batch, hygiene/security batch, test-style batch, go
  mod tidy, deadcode investigation, gap documentation
- ws-05 typescript: eslint caps, sonarjs, vitest plugin, knip + lockfile,
  dependency-cruiser, StrykerJS, bidi gate, gap documentation

### Phase 4: ws-06 remainder (after all gates)

- T02: root README + docs landing page (one commit)
- T03: harness rule mirrors (canonical first, then five mirrors)
- T05: runner final parity check against the full gate set
- T04: walk every epic and workstream AC box, record evidence in
  notes/final-ac-check.md

## Per-commit checks (adapted ci-lint-test)

This repo has no GitLab pipeline, so the ci-lint-test skill has nothing to
parse. The equivalent per-commit gates are: `scripts/verify-sync.sh` (byte
pairings), `bash -n` on every changed shell script, and the runner smoke
test when the runner changes. Rust, go, python, and typescript gate commands
run only when the touched folder's toolchain is installed locally.

## Verify acceptance criteria (end step)

Walk every box in the epic spec and all workstream specs against the
finished work. Record each as met or unmet, with the proving command or
README pointer, in notes/final-ac-check.md (ws-06 T04). An unmet box is a
bug in the work: fix it before declaring done.

## Final checks and MRs

- Run verify-sync.sh, bash -n on all scripts, and the runner smoke test one
  final time.
- Run the pre-mr-checklist skill on the repo.
- MRs need the ticket id for their titles. Nothing pushes or opens until the
  ticket id is provided.

## Status

Phase 1 executes now. Phases 2 and 3 are tool-gated (the install block in
Phase 2) and ready to run next, including parallel agents per worktree.
