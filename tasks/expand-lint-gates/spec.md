# Epic spec: expand the lint gates 

Status: planned 
Repo: https://github.com/PhillipChaffee/67-sus-95-clean 

## Summary (product and user view) 

This repo is a reference for starting new repositories. Each language folder 
carries a strict baseline: lint, type check, docs, formatter, and a coverage 
gate at 95%. A developer copies a folder (or runs its init skill) and starts 
from that baseline instead of inventing config. 

Today the baseline is missing gates we reviewed and agreed to add: 

- Hygiene gates that are the same for every language: spell check, secret 
  scanning, duplication detection, markdown lint, link check, and checks for 
  the repo's own shell and CI files. 
- Supply-chain gates: dependency advisories, license compliance, unused 
  dependencies, layer contracts, and lockfile integrity. 
- Language-specific gates that mainstream linters already support. 

From the user's view, after this epic: 

- A new repository built from any folder gets one labeled CI job per gate. 
  The job name tells the developer which gate failed. 
- Each gate failure points at the README section that explains the fix. 
- Every gate has a recorded proof: it passes a clean fixture and fails a 
  seeded violation. A gate with no failure proof does not ship. 
- Two metric families stay out by decision: coupling/cohesion dashboards and 
  Halstead / Maintainability Index / NPath. See notes/refusal-decisions.md. 

Note on "UX": this repo has no screens. Its UI is the README, the docs page 
(docs/index.html), and the CI run view. The "mockup" for UX checks is a 
recorded example: a CI run log and a rendered docs page, kept as fixtures in 
this epic. 

## Workstreams 

| folder | what | starts after | 
|---|---|---| 
| ws-01-repo-wide-gates | gates shared by all four languages | nothing | 
| ws-02-python | python-only gates | ws-01 | 
| ws-03-rust | rust-only gates | ws-01 | 
| ws-04-go | go linter batches | ws-01 | 
| ws-05-typescript | typescript-only gates | ws-01 | 
| ws-06-contracts-and-docs | add-language, READMEs, rule mirrors, final AC check | all others | 

ws-02 through ws-05 can run in parallel with each other. Inside one 
workstream, tasks touch shared files (the folder README and ci.yml), so land 
them in the listed order. Different workstreams touch different folders, so 
they do not conflict. 

## UX acceptance criteria 

Positive: 

- [ ] Each language folder's ci.yml has one labeled job per gate. A developer 
      can tell which gate failed from the job name alone. 
  - Make sure that the job names in each workflow file match the gate list 
    in that folder's README. 
- [ ] Each gate failure points to the README section for that gate. 
  - Make sure that the README section exists for each new gate, and that 
    the CI step output names the gate. 
- [ ] A developer runs one command locally and sees the pass or fail that CI
      will give.
  - Make sure that the folder runner (ws-06 T05) lists every PR-blocking
    gate, runs them in parallel, and prints one pass or fail line per gate.
- [ ] Running an init skill produces a repo with the full gate set. 
  - Run the init skill into a /tmp scratch repo. Grep the generated ci.yml 
    for every gate job name. 
- [ ] docs/index.html and the root README show the new gates for each 
    language. 
  - Grep README.md and docs/index.html for every new gate name. Save the 
    rendered page under the epic notes as the fixture (ws-06 T02 step 5). 

Negative: 

- [ ] No initialized repo carries a disabled new gate. Every ignore in every 
      config carries a written reason. 
  - Grep each config for disable and ignore entries. Each carries a reason. 
- [ ] No gate is warn-only. Each gate exits nonzero on a violation. 
  - Run each gate command against a seeded violation fixture. The exit 
    code must be nonzero. 

## Technical acceptance criteria 

Positive: 

- [ ] Every new gate has: a pinned tool version recorded in the folder 
      README, a config file, a CI step that runs the README command, a green 
      fixture run, and a seeded-failure run. Both outputs are recorded in the 
      README in the same style as the coverage proofs. 
- [ ] scripts/verify-sync.sh pairs every new canonical config with a 
      byte-identical template copy and passes. 
- [ ] The repo's own CI runs the hygiene gates on the repo itself (its 
      scripts, workflows, and markdown). 
- [ ] Each workstream spec has both positive and negative acceptance
      criteria, all mechanically checkable.
- [ ] Each language folder ships a local runner (run-gates.sh) that runs the
      PR-blocking gates from the folder README in parallel, prints a per-gate
      pass or fail summary, and exits nonzero on any failure. Its gate list
      matches the ci.yml job list. Each gate task also records the measured
      wall time of its command on the template project in the folder README.

Negative: 

- [ ] No gate ships without a failure proof. 
- [ ] No gate is warn-only. 
- [ ] No refused metric (LCOM, instability dashboards, Halstead, Maintainability 
      Index, NPath) appears as a gate anywhere in the repo. 
- [ ] No task adds a gate for a language where no maintained tool exists.
      Those stay documented as accepted gaps in the folder README instead.
- [ ] No PR-blocking gate runs only in CI. Mutation testing is the only
      scheduled-only gate, and the README and the runner say so. 

## How this epic runs 

- One branch per workstream: `phillip/expand-lint-gates-wsN-short-name`. 
- Tasks inside a workstream land in the listed order (they share files). 
  Workstreams run in parallel. 
- Commit after each task. Run the ci-lint-test skill for the repo before the 
  commit. 
- Before opening MRs: have the ticket id ready (MR titles need it), and run 
  the pre-mr-checklist skill. 
- Final step for the epic: walk every AC box above against the finished work 
  and record the result in notes/ (this is ws-06 T04). 