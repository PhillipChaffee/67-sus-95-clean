# ws-02 spec: python gates 

Status: planned · Starts after ws-01 · Parent: ../spec.md 
Folder: `python/`

## Summary (product and user view) 

Python is the most covered folder already (ruff `ALL`, mypy strict, branch 
coverage 95%, formatter). This workstream adds the python-only gates the 
audit found: unused-dependency detection, dead-code detection, and 
import-layer contracts. It also closes the TODO-policy gap (FIX002 is 
currently ignored) and writes down the gaps that have no tool, so the README 
stays honest about what is and is not enforced. 

User view: a python repo built from this folder gets the same supply-chain 
and hygiene gates as every other language, plus python-native layer rules. 
The README's "what is enforced" list grows. The trade-offs section records 
what was deliberately left out and why. 

Shared pattern: 

1. Pin the tool from its official docs. 
2. Write the config with a reason for every choice. 
3. Add the CI job in `python/ci.yml` and pair it with the byte-identical 
   template copy. 
4. Add the README section: command, pin, remedy, trade-offs. 
5. Prove the gate both ways and record both outputs. 
6. Run verify-sync.sh and the repo lint steps. Commit. 

## UX acceptance criteria 

Positive: 

- [ ] `python/ci.yml` has one labeled job per new gate, 
      and the job runs the exact README command. 
- [ ] Each gate's failure output names the violating file/package. 
- [ ] The python README lists every new gate with its remedy. 

Negative: 

- [ ] No new gate passes on a seeded violation. 
- [ ] No new ignore added to `pyproject.toml` without a reason. 
- [ ] No "documented gap" claims enforcement that does not exist. 
  - Match each documented gap against python/ci.yml job names. A gap listed 
    as not enforced must have no matching CI job. 

## Technical acceptance criteria 

Positive: 

- [ ] Each new tool version is pinned in the README and install command. 
- [ ] Each gate has a green-fixture run and a seeded-failure run recorded in 
`python/README.md`. 
- [ ] `python/init-python-repo/templates/` carries byte-identical copies of 
      every new config. Scripts/verify-sync.sh pairs them and passes. 
- [ ] The init skill's gate list still matches the README. 

Negative: 

- [ ] No gate is warn-only. 
- [ ] No refused metric is introduced. 
- [ ] The coverage gate (95%, branch) is not weakened by any change here. 

## Tasks (in order) 

| task | gate | 
|---|---| 
| T01 | deptry: unused dependencies | 
| T02 | vulture: dead code | 
| T03 | import-linter: layer contracts and cycles | 
| T04 | TODO policy: stop ignoring FIX002 | 
| T05 | lockfile integrity: hash-pinned installs | 
| T06 | mutation testing: mutmut (scheduled) | 
| T07 | document the accepted no-tool gaps | 

## Note on scope 

No-tool gaps (cognitive complexity, nesting depth, repeated literals, 
class-size caps, assertion-less tests) are documented as accepted gaps, not 
built: see notes/refusal-decisions.md and notes/gap-inventory.md in the epic, and 
the folder README update in T07. 