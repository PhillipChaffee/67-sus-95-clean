# T03 (python) gate: import-linter layer contracts and cycles 

Depends on: T01 (shares the CI file) · Touched: 
`python/.importlinter` (new), ci.yml + template copy, `python/README.md`, 
templates, make sure that-sync list 

## Steps 

1. Pin import-linter from its official docs. 
2. Define the layer contract for the template project: layers that must not 
   import upwards, forbidden imports between named modules, and cycle 
   detection. Keep the contract small and obvious for a fresh repo. Every 
   rule carries a reason. 
3. Add an `Import layers` CI job (command per README) + template copy. 
4. README section: command, pin, remedy ("move the import, or justify a new 
   contracted exception"), trade-offs. 
5. Prove: clean pass. Add a forbidden import to a fixture and make sure that 
   failure. Record both outputs. 
6. verify-sync.sh + repo lint. Commit. 

## Acceptance criteria 

Positive: 

- [ ] import-linter exits 0 on the template project. 
- [ ] A seeded upward (or forbidden) import fails. Output names the modules. 
- [ ] Every contract rule carries a reason. 

Negative: 

- [ ] No contract rule without a reason. 
- [ ] The contract covers the template's real modules. 
  - List the covered paths in the proof. The seeded forbidden import sits 
    inside a covered module. 
- [ ] verify-sync.sh passes. 