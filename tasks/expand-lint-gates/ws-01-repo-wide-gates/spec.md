# ws-01 spec: repo-wide gates

Status: planned · Runs first · Parent: ../spec.md

## Summary (product and user view)

Seven gates are identical for every language, so they are built once and
wired into all four folders' CI templates plus the repo's own CI:

| gate | tool | what it catches |
| --- | --- | --- |
| spell check | typos | misspelled words in code, comments, docs |
| docs hygiene | markdownlint-cli2 + lychee | broken markdown style, dead links |
| secrets | gitleaks | committed credentials and tokens |
| duplication | jscpd | copy-pasted code blocks |
| advisories | osv-scanner | known vulnerabilities in dependencies |
| licenses | osv-scanner --licenses | dependency licenses we do not allow |
| artifact lint | shellcheck, shfmt, actionlint, yamllint | bad shell scripts and CI YAML |

User view: a failing CI job is named after the gate, and the failure output
says which file tripped it. The repo's own scripts and workflows are checked
by the same gates (the repo dogfoods its own rules).

Shared pattern for every task in this workstream:

1. Pin the tool version from its official docs. Record it in each folder
   README and the root README.
2. Write the config at the repo root, with a reason for every choice.
3. Add the gate as a labeled job in all four `<lang>/ci.yml`
   templates AND pair each edited ci.yml with its byte-identical template copy
   under `<lang>/init-<lang>-repo/templates/` so verify-sync.sh passes.
4. Add a root `.github/workflows/hygiene.yml` job for this repo's own files.
5. Add the command and the trade-off note to each folder README.
6. Prove the gate both ways: a clean run passes, a seeded violation fails.
   Record both outputs in the folder README.
7. Run scripts/verify-sync.sh and the repo's own lint steps before committing.

## UX acceptance criteria

Positive:

- [ ] All four ci.yml files have a labeled job per gate in this workstream.
- [ ] A seeded violation (a planted typo, a fake secret, a dead link) fails
      exactly the matching job, and its output names the file.
- [ ] The root hygiene workflow runs on the repo itself.

Negative:

- [ ] No gate here exits 0 on a seeded violation.
- [ ] No allowlist entry exists without a reason (gitleaks and jscpd
      allowlists are the risk).

## Technical acceptance criteria

Positive:

- [ ] Each tool version is pinned and recorded in the READMEs.
- [ ] Each config parses cleanly (JSON/YAML/TOML as applicable).
- [ ] verify-sync.sh passes after every ci.yml edit.
- [ ] Each gate has a green-fixture run and a seeded-failure run recorded in
      the folder READMEs.

Negative:

- [ ] No gate is warn-only.
- [ ] No refused metric is introduced by any of these tasks.

## Tasks (in order)

| task | gate |
| --- | --- |
| T01 | typos spell check |
| T02 | markdownlint-cli2 + lychee link check |
| T03 | gitleaks secret scan |
| T04 | jscpd duplication |
| T05 | osv-scanner advisories + licenses |
| T06 | shellcheck, shfmt, actionlint, yamllint |
| T07 | commitlint decision (optional gate: decide, then build or refuse with a reason) |

Tasks within this workstream touch the same ci.yml files, so land them in
order. Rebase between tasks. The workstream as a whole runs in parallel with
ws-02..ws-05.
