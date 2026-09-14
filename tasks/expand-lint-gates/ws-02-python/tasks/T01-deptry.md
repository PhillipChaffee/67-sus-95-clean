# T01 (python) gate: deptry unused dependencies

Depends on: none within ws-02 · Touched: `python/pyproject.toml` or
dedicated config, `python/ci.yml` + template copy,
`python/README.md`, `python/init-python-repo/templates/`,
`python/init-python-repo/SKILL.md` if it lists gates

## Steps

1. Pin deptry from its official docs. Make sure that it reads the template project's
   dependency layout.
2. Write the config (or command flags): strictest usable settings. Every
   exclusion carries a reason.
3. Add an `Unused dependencies` job to `python/ci.yml` and
   its template copy. Command matches the README.
4. README section: command, pin, remedy ("remove the dependency or justify
   the exclusion"), trade-offs.
5. Prove both ways: clean pass. Add a dependency entry that no module imports, and
   make sure that the run fails. Record both outputs.
6. verify-sync.sh + repo lint. Commit.

## Acceptance criteria

Positive:

- [ ] deptry exits 0 on the template project as-is.
- [ ] Seeded unused dependency fails. Output names the package.
- [ ] Tool pin recorded in README. Config entries carry reasons.

Negative:

- [ ] No exclusion without a reason.
- [ ] Gate is not warn-only.
- [ ] verify-sync.sh passes. No template drift.
