# T04 gate: jscpd duplication detection (all languages)

Depends on: none · Touched: jscpd config (new, repo root), all four
ci.yml templates + copies, folder READMEs, `scripts/verify-sync.sh`

## Steps

1. Pin jscpd from its official docs. Decide the report format and threshold.
2. Write the config: a strict-but-usable token-overlap threshold (propose one,
   make sure that against jscpd docs, record the reason), and per-language ignore
   lists for config/template files where repetition is intentional.
3. Add a `Duplication check` job to all four ci.yml templates + template
   copies, and the repo's own hygiene workflow.
4. README section per folder: command, threshold and its reason, remedy
   ("extract the shared code into one place"), trade-offs (what the ignore
   list covers and why).
5. Prove: clean run passes at the threshold. Duplicate a code block into a
   fixture and make sure that the run fails. Record outputs.
6. verify-sync.sh + repo lint. Commit.

## Acceptance criteria

Positive:

- [ ] jscpd exits 0 on the repo at the chosen threshold.
- [ ] Seeded duplicated block fails the run. Output names the files.
- [ ] Threshold and every ignore entry carry a reason in config or README.

Negative:

- [ ] No language excluded from the gate.
- [ ] Threshold is not so loose that a real copy-paste passes (the seeded
      failure is the check).
- [ ] verify-sync.sh passes.
