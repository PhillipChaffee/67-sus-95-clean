# T04 (go) gate: go mod tidy -diff 

Depends on: T01 · Touched: `go/ci.yml` + template 
copy, `go/README.md` commands section, templates, make sure that-sync list 

## Steps 

1. Add a CI step running `go mod tidy -diff` (or the equivalent at the pinned 
   toolchain): this fails when the module files and the imports disagree, 
   which is the go-native unused-dependency gate. 
2. README: add the command to the Commands section with one line on what it 
   catches and the remedy ( `go mod tidy`). 
3. Prove: clean pass. Add an unused require to go.mod in a scratch copy and 
   make sure that the step fails. Record outputs. 
4. verify-sync.sh + repo lint. Commit. 

## Acceptance criteria 

Positive: 

- [ ] `go mod tidy -diff` exits 0 on the folder's example project. 
- [ ] A seeded go.mod/go.sum inconsistency fails. Output names the diff. 

Negative: 

- [ ] No separate third-party unused-dep tool added on top (the toolchain 
      gate is the go-native answer. Note this in the README to avoid 
      duplicating cargo-shear-style tooling). 
- [ ] verify-sync.sh passes. 