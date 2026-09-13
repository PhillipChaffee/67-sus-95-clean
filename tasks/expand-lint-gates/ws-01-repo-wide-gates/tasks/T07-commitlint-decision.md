# T07 decision: commit-message linting (commitlint)

Depends on: none · Touched: ../notes/decision-commitlint.md (new).
If adopted, config + ci.yml edits per T01's pattern.

## Steps

1. Evaluate commitlint (or the tool of choice) for the four initialized-repo
   workflows: what it enforces (conventional-commit format, subject rules),
   what it costs, and whether the repo's own MR conventions (title must carry
   the ticket id) can be expressed by it.
2. Decide: adopt or refuse. Either way, write the decision to
   ../notes/decision-commitlint.md with the reason, following the gate
   contract for "adopt" and the refusal format of
   ../../notes/refusal-decisions.md for "refuse".
3. If adopted: full gate treatment (pin, config with reasons, CI job in all
   four templates + template copies, README sections, both-way proof,
   make sure that-sync). If refused: record the reason. Do not build.

## Acceptance criteria

Positive (adopt path):

- [ ] A decision note exists with a clear adopt/refuse outcome and reasons.
- [ ] If adopted: all gate-contract points hold (pinned tool, binary gate,
      proof both ways, README sections, template sync).

Negative:

- [ ] No half-adopted state: either the gate is fully wired with proofs, or
      the refusal note records why it was skipped.
- [ ] The note does not claim enforcement that does not exist.
