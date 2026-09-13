# T06 (go) document the accepted no-tool gaps 

Depends on: T01–T05 · Touched: `go/README.md` trade-offs section, 
`../../notes/gap-inventory.md` (go section), init skill gate list if needed 

## Steps 

1. Write the accepted-gap list into the README trade-offs section in the 
   folder's style: commented-out-code detection (no gocritic checker covers 
   it today. Look that up again before writing), assertion-less-test detection (only 
   mutation testing catches it), mutation testing itself (no maintained go 
   tool at planning time. Look that up again), plus anything the batches above turn out 
   not to cover. 
2. One sentence each: the missing signal, why the stack cannot see it, 
   what changes the answer. 
3. Point at the epic refusal note for refused families. 
4. Update the init skill gate list if it enumerates gates. 
5. verify-sync.sh + repo lint. Commit. 

## Acceptance criteria 

Positive: 

- [ ] Each accepted gap is listed with a reason in the README. 
- [ ] The epic gap inventory matches the README list. 

Negative: 

- [ ] No gap described as enforced. 
- [ ] No roadmap promises: gaps are current facts. 