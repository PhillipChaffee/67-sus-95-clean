# T01 (ws-06) add-language skill contract update 

Depends on: all ws-01..ws-05 folder work · Touched: 
`add-language/SKILL.md`, README references to add-language if any 

## Steps 

1. Read add-language/SKILL.md end to end. Its workflow has four sections: 
   research, author, validate, stop lines. 
2. Extend the research step: the researcher must now also pin down, from 
   official sources, the tool for each new gate family the language's 
   ecosystem supports (spell check, secret scan, advisories, licenses, 
   unused deps, layer rules, markdown/link/artifact hygiene) and record 
   which families have no tool. 
3. Extend the author step: the folder must carry the new config files and 
   CI jobs for every family that has a tool. Accepted gaps go in the folder 
   README the same way T05-style tasks do it in the language workstreams. 
4. Extend the validate step: new configs parse like the existing ones 
   (TOML/YAML/JSON per type). Every new gate gets a both-way proof before 
   the folder counts. 
5. Keep the invariant unchanged (coverage gate must provably fail under 
   95%). Keep the existing voice and structure: edits are additive. 
6. Update the root README table if add-language's text changes what it 
   produces (coordinate with T02). 
7. verify-sync.sh + repo lint. Commit. 

## Acceptance criteria 

Positive: 

- [ ] The skill's workflow names every new gate family and where it lands 
      (config file, CI job, README section). 
- [ ] The validate section requires parsing the new config files and a 
      failure proof for each new gate. 

Negative: 

- [ ] The coverage invariant is not weakened or restated. 
- [ ] The skill does not require refused metrics (coupling dashboards, 
      Halstead/MI/NPath) of new languages. 
- [ ] The skill does not promise gates for families with no tool. It 
      requires documenting them instead. 