# T05 (go) dead-code gate investigation (x/tools deadcode) 

Depends on: none (independent file-wise. Lands after T04) · Touched: 
`go/ci.yml` + template copy (only if adopted), `go/README.md` (lint list or 
trade-offs), templates, make sure that-sync list, decision note 

## Steps 

1. Research `golang.org/x/tools`' deadcode command at its current version: 
   what it detects (uncalled functions across the whole program), how it is 
   invoked, and: critically: whether it exits nonzero on findings at a 
   pinned version. Make sure that from the official docs and a scratch run. Do not 
   assume. 
2. Decide: adopt or refuse. 
   - Adopt: it must be a binary gate (nonzero exit on findings) at the 
     pinned version, with a README section, both-way proofs, template sync. 
     Note how it treats test-only and reflective code. 
   - Refuse: write the decision to ../notes/decision-deadcode.md (new) and 
     the README 
     trade-offs section using the refusal format, and mark go dead-code 
     detection as covered only by the `unused` linter (already enabled). 
3. Either way, record the outcome in this task file and the README. 
4. verify-sync.sh + repo lint. Commit. 

## Acceptance criteria 

Positive: 

- [ ] A decision exists with evidence from a scratch run (actual command 
      output, not a doc claim). 
- [ ] If adopted: gate-contract points hold (binary gate, both-way proofs, 
      README, template sync). 

Negative: 

- [ ] No half state: fully wired with proofs, or formally recorded as an 
      accepted gap. 
- [ ] No wrapper script invented to fake a nonzero exit if the tool does not 
      support one. 