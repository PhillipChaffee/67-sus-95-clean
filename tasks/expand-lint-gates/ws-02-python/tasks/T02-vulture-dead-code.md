# T02 (python) gate: vulture dead-code detection 

Depends on: T01 (shares the CI file) · Touched: 
`python/pyproject.toml` or vulture config, ci.yml + template copy, 
`python/README.md`, templates, make sure that-sync list 

## Steps 

1. Pin vulture from its official docs. Run it on a scratch project first and 
   measure the noise (vulture flags dynamically-used names). 
2. Decide the policy: which categories are checked (dead functions, unused 
   classes) and how the allowlist works (a `vulture` whitelist file, or 
   inline `# noqa`-style comments per vulture's docs). Every allowlist entry 
   gets a reason. 
3. If measured noise makes the gate unusable, STOP and record vulture as an 
   accepted gap using the refusal format: see 
   ../../notes/refusal-decisions.md for the format. Do not ship a noisy gate. 
4. Add a `Dead code` CI job (command from the README) + template copy. 
5. README section: command, pin, allowlist policy, remedy, trade-offs. 
6. Prove: clean pass. Add an uncalled function and make sure that it fails. Record. 
7. verify-sync.sh + repo lint. Commit. 

## Acceptance criteria 

Positive: 

- [ ] Gate exits 0 on the template project. 
- [ ] Seeded dead function fails. Output names it. 
- [ ] Allowlist policy documented. Entries carry reasons. 

Negative: 

- [ ] No shipped gate with unmeasured noise (the scratch measurement is 
      recorded or the task ends in a documented refusal). 
- [ ] No warn-only run. verify-sync.sh passes. 