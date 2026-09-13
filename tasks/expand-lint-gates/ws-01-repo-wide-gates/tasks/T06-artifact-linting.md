# T06 gate: own-artifact linting (shell, shfmt, actionlint, yamllint) 

Depends on: none · Touched: shellcheck/shfmt/yamllint configs (new, 
repo root), all four ci.yml templates + copies, folder READMEs, 
`scripts/verify-sync.sh`

## Steps 

1. Pin shellcheck, shfmt, actionlint, and yamllint from official docs. 
2. Write configs: 
   - shellcheck: strict shell checks for `scripts/*.sh` and any shell in 
     templates. Every disabled check carries a reason. 
   - shfmt: formatting check mode ( `-d`) with the style flags recorded. 
   - actionlint: default checks for every workflow file (repo's own and the 
     per-folder ci.yml templates). 
   - yamllint: a strict-but-usable rule set. Deviations from default carry 
     reasons. 
3. Add an `Artifact lint` job (or split jobs) to all four ci.yml templates + 
   template copies, and to the repo's own hygiene workflow. The repo's own 
   scripts/*.sh and workflows get checked here: the repo dogfoods its own 
   gates. 
4. README section: the four commands, pins, remedies, trade-offs. 
5. Prove: clean pass on the repo. Seed a shell bug (unquoted variable) and a 
   YAML syntax error in scratch files, make sure that they fail. Record outputs. 
6. Fix any findings the new gates catch in the repo's own files (same task). 
7. verify-sync.sh + repo lint. Commit. 

## Acceptance criteria 

Positive: 

- [ ] All four checks exit 0 on the repo as-is (after fixing findings). 
- [ ] Seeded shell and YAML violations fail. Outputs name the file and line. 
- [ ] Repo's own scripts and workflows are covered by the checks. 

Negative: 

- [ ] No shellcheck rule disabled without a reason. 
- [ ] No warn-only check (nonzero exit on violation). 
- [ ] verify-sync.sh passes. 