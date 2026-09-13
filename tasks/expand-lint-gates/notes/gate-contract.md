# Note: the gate contract

This is the test every new gate must pass before it ships. It follows the
repo's house rules (see the root README).

A real gate:

1. Has a precise definition and a threshold we can defend (a mainstream
   standard like McCabe's 10, or a threshold we justify in the README).
2. Comes from a maintained, mainstream tool. The tool version is pinned and
   recorded in the folder README.
3. Fails the build. The gate command exits nonzero on a violation. No
   warn-only gates.
4. Has a recorded proof, both ways: a clean fixture passes, a seeded
   violation fails. Both command outputs go in the folder README, in the same
   style as the coverage proofs ("THE GATE IS TESTED").
5. States the remedy: what a developer does when the gate fires.
6. Carries a reason on every config entry. No rule is enabled, disabled, or
   ignored without a why.
7. Has a byte-identical template copy, and scripts/verify-sync.sh pairs them.

Why each point exists: rules 1–4 keep gates honest and deterministic. Rule 5
keeps the gate useful (a failure you cannot act on is noise). Rules 6 and 7
keep the config honest and the templates in sync.
