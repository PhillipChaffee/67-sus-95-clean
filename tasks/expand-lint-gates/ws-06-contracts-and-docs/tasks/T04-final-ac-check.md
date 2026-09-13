# T04 (ws-06) walk every acceptance criterion (epic-wide) 

Depends on: everything else in the epic · Touched: 
`../notes/final-ac-check.md` (new), any fix commits the sweep turns up 

## Steps 

1. Walk every acceptance-criteria box in the epic spec and in all six 
   workstream specs against the finished work. 
2. For each box: record checked/unchecked, the command or grep that proves 
   it, and the output (or a pointer to the README proof section). 
3. Fix what fails: a failed AC is a bug in the work, not in the criteria. Fix the work (or, with user approval, update the plan and record why). 
4. Write notes/final-ac-check.md: one line per AC: met/unmet, evidence. 
5. Run the repo's full CI checks per folder (the ci-lint-test skill) and the 
   pre-mr-checklist skill on each changed repo before pushing. 
6. Commit the check note. The epic is done only when every box is met. 

## Acceptance criteria 

Positive: 

- [ ] notes/final-ac-check.md exists and records every AC box with evidence. 
- [ ] Every box is met, or an unmet one is escalated to the user with a 
      reason before any completion claim. 

Negative: 

- [ ] No AC box left unverified while declaring the epic done. 
- [ ] No box marked met on intent: only on a recorded command output. 