# Local runner design notes

Why parallel locally: most gates are single core and work on independent
file sets, so they run well as concurrent processes. The compile-bound gates
(clippy, llvm-cov, tsc, mypy, go build) set the wall time. A -j cap keeps a
laptop responsive while the light gates finish.

Why no container wrapper: the house commands run bare, and CI runs exactly
the documented local commands. A container adds drift between local and CI.

CI parity rule: the runner gate list and the ci.yml job list must match both
ways. The grep check in the README is the proof. This kills the classic
failure where a gate exists in CI but nobody can run it locally, or a local
check never reaches CI.

Timing expectations: the sub-second hygiene gates (typos, markdownlint,
shellcheck, shfmt, yamllint, actionlint) cost less than runner startup on
GitHub, so wall time in CI is roughly the slowest job plus runner startup,
not the sum of jobs. The slow jobs are the compile-bound ones and the test
plus coverage gate. That is why every gate task records a measured wall time,
so the numbers come from runs, not guesses.

Job-count trade: one job per gate gives the clearest failure signal. If a
repo ever grows so many jobs that runner startup dominates, group the
sub-second hygiene gates into one job whose steps still name each gate in
the failure output.