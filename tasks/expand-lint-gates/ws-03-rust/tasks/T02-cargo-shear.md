# T02 (rust) gate: cargo-shear unused dependencies 

Depends on: T01 (shares the CI file) · Touched: 
`rust/ci.yml` + template copy, `rust/README.md`, templates, 
make sure that-sync list 

## Steps 

1. Pin cargo-shear from its official docs. Note how it handles 
   feature-gated and build-script dependencies (document false-positive 
   handling. Cargo-shear's docs describe its detection limits). 
2. Add an `Unused dependencies` CI job running the README command. 
3. README section: command, pin, remedy ("remove the dependency, or document 
   why the tool cannot see the use"), trade-offs. 
4. Prove: clean pass. Add an unused dependency to a scratch manifest and 
   make sure that it fails. Record outputs. 
5. verify-sync.sh + repo lint. Commit. 

## Acceptance criteria 

Positive: 

- [ ] cargo-shear exits 0 on the folder's example project. 
- [ ] A seeded unused dependency fails. Output names the crate. 
- [ ] Pin and remedy recorded in the README. 

Negative: 

- [ ] Detection limits are documented, not hidden (README names what 
      cargo-shear cannot see). 
- [ ] Gate is not warn-only. verify-sync.sh passes. 