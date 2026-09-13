# T07 (python) document the accepted no-tool gaps 

Depends on: T01–T06 (README edits land last) · Touched: 
`python/README.md` (trade-offs section), `python/init-python-repo/` if it 
repeats the gate list, `../../notes/gap-inventory.md` (update the python 
section) 

## Steps 

1. Write the accepted-gap list into the README's trade-offs section, in the 
   folder's existing style: what is NOT enforced and why there is no gate. 
   Items: cognitive complexity (no ruff/mypy rule), nesting-depth caps, 
   repeated literal to constant, interface/class-size caps, assertion-less test 
   detection (mutation testing covers it). 
2. For each, one sentence: what the missing signal is, why the current stack 
   cannot catch it, and what changes the answer (a mainstream tool). 
3. Note the refusals in one line and point at the epic's refusal note. 
4. Update the init skill's gate list if it enumerates gates. 
5. verify-sync.sh + repo lint. Commit. 

## Acceptance criteria 

Positive: 

- [ ] The README trade-offs section lists each accepted gap with a reason. 
- [ ] The gap inventory note matches the README wording (same list). 

Negative: 

- [ ] No gap is described as enforced. 
- [ ] No promised tool ("we will add X later"): gaps are stated as current 
      facts, not roadmaps. 