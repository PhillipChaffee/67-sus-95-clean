# T03 (ws-06) harness rule mirrors

Depends on: ws-01..ws-05 (the rule text must describe the final gate
set) · Touched: `~/.agents/rules/new-repo-setup.md` (canonical),
`~/.config/opencode/AGENTS.md`, `~/.claude/rules/new-repo-setup.md`,
`~/.codex/AGENTS.md`, `~/.cursor/rules/new-repo-setup.mdc`,
`~/.config/goose/.goosehints`

## Steps

1. Update the canonical rule first
   ( `~/.agents/rules/new-repo-setup.md`): its description of the baseline
   gains the new gate families (hygiene and supply-chain gates, same
   machine-enforced language). Keep the file's existing structure and
   footer.
2. Mirror the updated text into all five harness copies, each in its own
   format (the mirrors' footers say "edit there, mirror here").
3. Make sure that the update is consistent with the root README (the rule and the
   README must describe the same baseline).
4. Note what changed in ../notes/mirrors.md (append an entry).

## Acceptance criteria

Positive:

- [ ] The canonical rule describes the expanded baseline. All five mirrors
      match it (diff the shared body text).
- [ ] The rule's repo pointer stays the GitHub copy
      (github.com/PhillipChaffee/67-sus-95-clean): no local paths.

Negative:

- [ ] No mirror still describes the old five-column baseline.
- [ ] No mirror points at the local checkout path.
- [ ] The condensed goose variant stays within 12 lines (measure it with
      wc -l). Record the bound in notes/mirrors.md.
