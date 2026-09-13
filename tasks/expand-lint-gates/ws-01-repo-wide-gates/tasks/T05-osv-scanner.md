# T05 gates: osv-scanner advisories + licenses (all languages) 

Depends on: none · Touched: osv-scanner config (new, repo root), 
python, go, and typescript ci.yml templates + copies (rust uses cargo-deny 
instead, see ws-03 T01), folder READMEs, `scripts/verify-sync.sh`

## Steps 

1. Pin osv-scanner from its official docs. 
2. Write the config for both gates: 
   - Advisories: scan the lockfile/manifest of each language (package-lock 
     types, go.mod/go.sum, Cargo.lock, requirements/lockfile in use). 
   - Licenses: `--licenses` with an allow-list of license ids we accept 
     (MIT, Apache-2.0, BSD, ISC as the starting set). Every entry carries a 
     reason. Denied licenses are listed with a why. 
3. Add `Dependency advisories` and `License check` jobs to the python, go, 
   and typescript ci.yml templates + template copies, and to the repo's own 
   hygiene workflow. Rust gets these gates from cargo-deny (ws-03 T01), so 
   skip the rust folder here to avoid duplicate jobs. Run the README 
   commands exactly. 
4. README section per folder: commands, pin, remedy ("bump or replace the 
   flagged dependency. Add a reason-carrying ignore only with a date"), and 
   the note that advisories fail the build while the report is still written. 
5. Prove: clean run passes. Seed a known-vulnerable version or a denied 
   license in a scratch manifest and make sure that it fails. Record outputs. 
6. verify-sync.sh + repo lint. Commit. 

## Acceptance criteria 

Positive: 

- [ ] Both gates exit 0 on the repo as-is. 
- [ ] Seeded advisory (or denied license) fails. Output names the package. 
- [ ] License allow/deny lists carry reasons. 

Negative: 

- [ ] Advisories gate does not pass while a known-vulnerable pin is present. 
- [ ] No ignore of a vulnerability without a reason and a date. 
- [ ] verify-sync.sh passes. 