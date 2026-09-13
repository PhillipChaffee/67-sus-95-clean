# T03 (ts) vitest eslint plugin (test style + expect-expect) 

Depends on: T02 · Touched: `typescript/eslint.config.mjs`, 
`typescript/package.json`, `typescript/README.md`, templates, make sure that-sync 
list 

## Steps 

1. Pin @vitest/eslint-plugin from its docs. Use the setup that reads the 
   project's vitest version. 
2. Enable `expect-expect` (assertion-less tests fail) plus the test-style 
   slice the audit targeted. Keep the slice strict but focused. Each enabled 
   or disabled rule carries a reason. 
3. Scope the config to test files (the plugin's rules only apply to 
`*.test.*` per its docs). 
4. README: lint list entries (rule, reason, remedy, trade-offs). 
5. Prove: seed a test with no assertion (expect-expect fires) and a style 
   violation. Record outputs. 
6. verify-sync.sh + repo lint. Commit. 

## Acceptance criteria 

Positive: 

- [ ] Plugin pinned and loaded from the config (vitest-version-aware). 
- [ ] Seeded assertion-less test fails `npm run lint`. 
- [ ] README entries carry reasons and remedies. 

Negative: 

- [ ] Test-style rules do not leak into non-test files (config scoping 
      check). 
- [ ] Existing tests still pass lint. Make sure that-sync passes. 