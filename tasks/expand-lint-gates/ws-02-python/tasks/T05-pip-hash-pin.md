# T05 (python) lockfile integrity: hash-pinned installs

Depends on: T01 (shares CI file) · Touched: a hash-pinned
requirements lockfile for the template install set (new),
`python/ci.yml` + template copy, `python/README.md`, templates,
`scripts/verify-sync.sh`

## Steps

1. Decide the shape with the folder's install style in mind: the README's
   install command pins exact versions ( `pip install "ruff==0.16.6" ...`).
   Hash-pinning needs a requirements file with `--hash` entries. Introduce a
   hash-pinned lockfile for the documented install set, generated and
   verified with pip's hash-checking mode ( `--require-hashes`) per pip's
   official docs. If the house install-command style conflicts with
   hash-pinning, record the decision and either adapt the install command or
   record the gate as not applicable with a reason.
2. Add a `Lockfile integrity` CI step: install from the hash-pinned file with
`--require-hashes`. Any missing or wrong hash fails.
3. README: the command, the remedy ("regenerate the lock with pinned hashes
   never add a package without a hash"), trade-offs.
4. Prove: clean install passes. Remove one hash entry in a scratch copy and
   make sure that it fails. Record outputs.
5. verify-sync.sh + repo lint. Commit.

## Acceptance criteria

Positive:

- [ ] The hash-checked install exits 0 on the template project.
- [ ] A seeded missing/wrong hash fails the CI step.
- [ ] The README documents the hash-pinning policy.

Negative:

- [ ] No package in the lockfile without a hash (unless the task ended in a
      documented not-applicable decision).
- [ ] Gate is not warn-only. verify-sync.sh passes.
