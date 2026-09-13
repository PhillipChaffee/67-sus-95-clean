# T04 (python) TODO policy: stop ignoring FIX002 

Depends on: T02 (shares the config file) · Touched: 
`python/pyproject.toml` (ruff ignore list), `python/README.md` (lint ignore 
summary), templates, notes 

## Steps 

1. Decide the uniform TODO policy with the other workstreams in mind: the 
   house target is one rule everywhere: a TODO marker fails the build 
   (TypeScript already fails on todo/fixme via no-warning-comments. Go gets 
   godox. Rust gets a grep gate). 
2. For python: remove FIX002 from the ignore list (it currently reads "say 
   'resolve the issue'" while TD rules govern the rest). Look at whether TD001/ 
   TD003/TD004 already give the link discipline. Record how FIX002 and the TD 
   rules combine. 
3. Update the config comment and the README's ignore-group summary: the old 
   reason goes, the new policy reason takes its place. 
4. Prove: a seeded `# TODO` without an issue link fails `ruff check`. A TODO 
   with a linked issue passes. Record outputs. 
5. verify-sync.sh + repo lint (pyproject template copy!). Commit. 

## Acceptance criteria 

Positive: 

- [ ] `ruff check .` fails on a seeded bare `# TODO` (or `# TODO(abc)` with 
      no linked issue, per the TD rules). 
- [ ] The README's ignore-group summary no longer lists FIX002 as ignored, 
      and states the uniform TODO policy. 

Negative: 

- [ ] The ignore list does not contain FIX002 anymore. 
- [ ] No other rule was silently unignored: only FIX002, with a recorded 
      reason. 
- [ ] verify-sync.sh passes. 