# Note: ws-06 things to remember 

- The rule mirrors live outside this repo. The canonical copy is 
  ~/.agents/rules/new-repo-setup.md, mirrored into: 
  ~/.config/opencode/AGENTS.md (section new-repo-setup), 
  ~/.claude/rules/new-repo-setup.md, ~/.codex/AGENTS.md, 
  ~/.cursor/rules/new-repo-setup.mdc, ~/.config/goose/.goosehints 
  (condensed). Each mirror's footer says "edit there, mirror here": T03 
  must update the canonical first, then all five. 
- The mirror text describes the repo's gate set in one sentence ("lint, 
  type-check, docstring, formatter, coverage: 95% machine-enforced"). After 
  this epic that sentence is stale: the gate set also includes hygiene and 
  supply-chain gates. T03 rewrites that sentence everywhere, keeping each 
  mirror's format (frontmatter for the .mdc, condensed for goose). 
- The add-language skill's invariant (a folder is not merged until its 
  coverage gate provably fails a build under 95%) does NOT change. The new 
  families extend the research and author steps: the skill must require the 
  hygiene/supply-chain gates in the folder it authors. 
- The root README's "house rules" section lists shared guarantees. New 
  families (hygiene, supply-chain) belong there as new numbered rules or 
  folded into existing ones: keep the section's numbered-list shape. 
- docs/index.html is the landing page (see docs/). Mirror the README table 
  changes there so the two never disagree. 