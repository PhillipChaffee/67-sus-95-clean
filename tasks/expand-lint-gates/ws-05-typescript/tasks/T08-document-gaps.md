# T08 (ts) document the accepted no-tool gaps 

Depends on: T01–T07 · Touched: `typescript/README.md` trade-offs 
section, `../../notes/gap-inventory.md` (ts section), init skill gate list if 
needed 

## Steps 

1. Write the accepted-gap list into the README trade-offs section in the 
   folder's style. Items to make sure that before writing: SAST (no workable TS 
   tool per the audit), anything the sonarjs plugin does not actually ship 
   (commented-out code: make sure that in T02's findings), Go/Rust parity items. 
2. One sentence each: missing signal, why the stack cannot see it, what 
   changes the answer. 
3. Point at the epic refusal note for the refused families. 
4. Update the init skill gate list if it enumerates gates. 
5. verify-sync.sh + repo lint. Commit. 

## Acceptance criteria 

Positive: 

- [ ] Each accepted gap is listed with a reason in the README. 
- [ ] The sonarjs README mapping matches the plugin's real rule list 
      (verified against the pinned plugin docs). 

Negative: 

- [ ] No gap described as enforced. 
- [ ] No roadmap promises. 