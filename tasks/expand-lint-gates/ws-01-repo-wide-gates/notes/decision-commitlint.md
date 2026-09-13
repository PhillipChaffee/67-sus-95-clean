# Decision: commit-message linting (commitlint) — refused

Refused, with reasons:

1. The house already enforces the shape where it matters: MR titles carry
   the ticket id (merge-requests rule), and commit messages follow the
   conventional style through the engineering rules.
2. A commitlint install adds a node toolchain to every initialized
   repository for a check that review already performs, and its config has
   no single source to inherit from at init time.
3. The gate contract asks for a defensible threshold and a remedy; for
   commit messages, the remedy (rewrite history) is friction without a
   defect class the other gates miss.

Reopen if: a future repo needs commit-format enforcement for external
contributors, or the house adopts a shared commitlint config worth
inheriting.
