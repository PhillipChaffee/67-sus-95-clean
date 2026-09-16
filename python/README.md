# python/ — the Python strict baseline

The stack below is verified against the pinned tools, not folklore: every
ignore carries its reason, and the coverage gate was proven to fail a build
under 95% (both runs are recorded in the coverage section). Pin of record:
ruff 0.16.6, mypy 2.3.1, pytest 9.1.1, pytest-cov 7.1.0, coverage 7.16.0,
deptry 0.25.1, vulture 2.16, import-linter 2.15, mutmut 3.8.0 (nightly).

## What is enforced

### Linting — ruff

`pyproject.toml` carries the `[tool.ruff.lint]` table:

- `select = ["ALL"]` — every stable rule family joins by default; preview
  rules are NOT part of `ALL` (badges on the ruff rules page), and preview
  stays off, so the surface is stable only. The call here is
  ALL-minus-ignores, not an explicit list: an explicit list rots in the
  opposite direction — new sound families never join — and the rust baseline
  makes the same shape of choice with pedantic + nursery. The cost is paid in
  public: a new stable noisy rule appears at the next pin bump and either
  gets fixed or gets a reasoned ignore.
- Two ignore groups, every entry one reason (the config carries them inline;
  summarized here):
  - **Formatter-owned byte choices** (W191, E111, E114, E117, D206, D300,
    Q000–Q004, COM812, COM819, ISC002): enabling any of these makes
    `ruff format` warn per its own "Conflicting lint rules" list — they
    double-judge tokens the formatter already emits. (ISC001 stays on: at
    this pin it is not in the formatter's conflict set and no warning fires
    — verified.)
  - **Noise rules** (CPY001, TRY003, TD002): a copyright stamp is a
    legal-layer policy, not a code-quality signal; TRY003 demands a custom
    exception class per message while EM101/EM102 keep the message
    discipline instead; TD002 demands TODO authorship git blame already
    owns.
  - **TODO policy** — the uniform house one, with FIX002 back ON: a TODO
    marker fails the build, matching every other stack (TypeScript fails
    any todo/fixme comment through no-warning-comments, go fails any
    marker through godox, rust greps the tree). TD001/TD003/TD004 stay on
    and govern the tag, the issue link, and the colon wherever a TODO
    appears; the proof below shows a linked TODO still fails, because the
    gate bans the marker itself, link or no link.
- `per-file-ignores` for `tests/**`: a narrower bar, every line reasoned —
  test names replace docstrings (D1), pytest asserts with `assert` (S101),
  literals and fake credentials are the point of a test (PLR2004,
  S105–S108); everything else runs strict in tests too.
- E501 stays ON at `line-length = 100`: the formatter only makes a
  best-effort wrap (formatter docs), so E501 is what flags long strings and
  comments it cannot wrap.
- Deny, not warn, holds by exit code rather than flags: `ruff check .` exits
  nonzero on any diagnostic, so there is no warn-to-error arithmetic to
  maintain. `ruff format --check .` exits 1 when any file would change.

THE GATE IS TESTED (the TODO policy): a seeded bare `# TODO` fails
`ruff check .` (exit 1), and a TODO carrying an issue link still fails
because FIX002 bans the marker itself:

```text
your_package/core.py:15:3: TD003 Missing issue link for this TODO
your_package/core.py:15:3: FIX002 Line contains TODO, consider resolving the issue
```

### Documentation — ruff D (google)

- The `D` ruleset is the docstring machine — this baseline's
  `missing_docs` analog. D100, D101, D102, D103, D104 mean no undocumented
  module, class, method, function, or package passes `ruff check`. The bar
  is the house bar: a doc that only restates the name is the bug — it must
  say what the signature cannot (raises, params with meaning, wire names).
- `convention = "google"` selects the Google set and resolves the classic
  conflict pairs by construction: D211 (no blank line before a class
  docstring) vs D203, and D212 (summary on the first line) vs D213 demand
  opposite shapes, and Google keeps D211/D212, disabling D203/D213 —
  verified firing exactly that way under `select = ["ALL"]` (ruff settings
  table: google also drops D204, D215, D400, D401, D404, D406–D409, D413).
- D417 stays enabled: a documented parameter needs a description.
- Unlike the rust arrangement, no separate CI doc job is needed — D runs
  inside `ruff check .` like every other family.

### Types — mypy --strict + beyond

`[tool.mypy] strict = true` turns on the full strict kit. The exact flag
list (mypy 2.3.1 `--strict`): disallow_any_generics, disallow_subclassing_any,
disallow_untyped_calls, disallow_untyped_defs, disallow_incomplete_defs,
check_untyped_defs, disallow_untyped_decorators, warn_redundant_casts,
warn_unused_ignores, warn_return_any, no_implicit_reexport, strict_equality,
extra_checks. Note disallow_untyped_decorators is already inside strict —
no separate line is needed.

Beyond strict:

- `warn_unreachable = true` — mypy's docs say explicitly it is NOT part of
  strict. Dead branches and redundant conditions become errors after type
  analysis.
- `python_version = "3.12"` — the default is the running interpreter; pinned
  to the requires-python floor so the type scale does not drift between dev
  machines.

Known-flaky beyond-strict flags, documented here instead of enabled:

- `disallow_any_explicit` — bans writing `Any` in type positions; a
  gradually-typed ecosystem needs named `Any` boundaries (JSON, plugin
  seams), and the ban tends to become a wall of ignores. With warns-as-errors
  from `any-*` error codes left off, the boundary is still caught indirectly
  by `disallow_any_generics` and `warn_return_any` in strict.
- `disallow_any_expr` — bans every expression of type `Any`, which cascades
  one unannotated third-party call into an unmanageable spray.
- `disallow_any_unimported` — bans `Any`s inferred through unfollowed
  imports; useful late, punishing before the stub situation is settled.

### Comments — machine + policy

Machine: the D ruleset above and its per-file test carve-out; a TODO marker
fails the build (FIX002 on, the uniform TODO policy), and TD001/TD003/TD004
govern the tag, the issue link, and the colon wherever a TODO appears (an
author is not required); RUF100 fails the build on any unused `# noqa` so
suppression cannot rot.

Policy (no linter checks prose; review treats a violation as a bug): the
same four house rules the rust baseline ships — present state only;
why-not-what; `#NNN` cited only attached to a live constraint; nothing
displays a number no server sends (adapt that one to the domain). Ship them
verbatim in the new repo's AGENTS.md.

### Coverage — the gate

```bash
pytest   # the same command — the gate rides in addopts
```

`[tool.coverage.run] branch = true` (+ `[tool.coverage.report]
fail_under = 95`): branch coverage is ON per house rule. Branch destinations
are execution opportunities added to both the count and the percentage
(coverage.py branch docs), so the number reported is stricter than line
coverage. Measurement rides coverage.py's C tracer (`ctrace`, the default
core through Python 3.13; the 3.14+ sysmon default does not support branch
coverage in 3.12/3.13 terms — re-verify the gate if you raise the floor;
empirically fine on 3.13.3 and 3.14.2 at this pin). pytest exits nonzero
when the fail_under is unmet — that is the gate.

THE GATE IS TESTED: it fails a build under 95% (that is its acceptance
test), and the tests themselves passing does not save the job —
the coverage total is what fails:

```text
(green run)  "Required test coverage of 95.0% reached. Total coverage: 100.00%"
             ============================== 2 passed ... PYTEST-EXIT=0
(broken run) ERROR: Coverage failure: total of 71 is less than fail-under=95
             FAIL Required test coverage of 95.0% not reached. Total coverage: 71.43%
             ============================== 1 passed ... PYTEST-EXIT=1
```

The `-ra` in addopts reports every outcome except passed (pytest `--help`),
so skips and xpasses stay visible.

### Hygiene — spell check (typos)

`typos` checks every file for misspellings (typos 1.50.1, pinned in ci.yml;
configuration in the repo-root `.typos.toml`).

```bash
typos
```

Remedy: fix the spelling, or add the identifier to `.typos.toml` with a
reason (the config carries five, each with its reason: a ruff rule
family name, the deliberate mistyped-tag example, the seeded-proof quote
words, and GNU grep's PCRE flag token from the typescript bidi step).
Measured wall time: 0.02s on this repo.
THE GATE IS TESTED: a clean tree exits 0; a seeded misspelling fails:

```text
error: `recieve` should be `receive`
  ╭▸ ./proof-seed-typo.md:1:1
  │
1 │ recieve the calender
  ╰╴━━━━━━━
```

### Hygiene — markdown lint + link check

`markdownlint-cli2` lints every markdown file (v0.23.2; config in the
repo-root `.markdownlint-cli2.jsonc`) and `lychee` checks every link
(v0.24.2; config in the repo-root `lychee.toml`, retry then fail).

```bash
markdownlint-cli2 "**/*.md"
lychee --no-progress .
```

Remedy: fix the markdown or the link. The config carries four reasoned
entries (hand-wrapped prose, skill-doc headings, the centered banner, tab
indentation inside fenced shell). Measured wall times: markdown 0.3s,
links 1.0s. THE GATE IS TESTED: a clean tree exits 0; seeded violations
fail:

```text
markdownlint-cli2 "**/*.md":1 MD009/no-trailing-spaces Trailing spaces [Expected: 0 or 2; Actual: 3]
lychee: [ERROR] http://127.0.0.1:9/dead (at 1:1) | Connection refused
```

### Hygiene — secret scan (gitleaks)

`gitleaks` scans for committed credentials (v8.30.1, default rule set;
config in the repo-root `.gitleaks.toml`). CI scans the full git history
(`fetch-depth: 0`), so an already-committed secret is caught too; the local
runner scans the working tree with `--no-git`.

```bash
gitleaks detect --source . --redact     # CI: full history
gitleaks detect --no-git --redact       # local runner: working tree
```

Remedy: rotate the secret, purge it from history, and never allowlist a real
credential. Allowlist entries need a reason. Measured wall time: 0.2s on
this repo (20 commits). THE GATE IS TESTED: a clean tree exits 0 ("no leaks
found"); a seeded fake AWS key fails:

```text
Finding:     aws_access_key_id (aws-access-key-id)
Secret:      AKIA********************E/REDACTED
File:        proof-seed-secret.txt:1
```

### Hygiene — copy-paste detection (jscpd)

`jscpd` tokenizes every source file and fails above the duplication
threshold (v5.2.0; config in the repo-root `.jscpd.json`, threshold 5).

```bash
jscpd
```

Remedy: extract the shared code into one place. The config ignores four
intentionally-parallel shapes with reasons (template byte-copies, per-folder
CI files, per-folder runners, and the folder READMEs' shared hygiene
sections). Measured wall time: 0.04s on this repo. THE GATE IS TESTED: a
clean tree exits 0 (0.00% duplicated). The threshold measures the whole
tree, so the failure proof runs the same command on a scratch fixture with
two identical 10-line functions (58 of 120 tokens, 48% against the 5%
threshold) and records its exit code 1:

```text
Found 1 clones.
Clone found (python)
 - proof-dup-a.py [1:1 - 10:15] (10 lines, 58 tokens)
   proof-dup-b.py [1:1 - 10:15]
exit code: 1
```

### Hygiene — dependency advisories + licenses (osv-scanner)

`osv-scanner` scans every lockfile for known vulnerabilities and reports
dependency licenses against an allow-list (v2.5.1). This repository itself
carries no lockfiles, so the step lives in each folder's CI and runner: it
targets the initialized repository, where the lockfiles exist.

```bash
osv-scanner scan -r .
osv-scanner scan -r . --licenses="MIT,Apache-2.0,ISC,BSD-3-Clause,BSD-2-Clause,MPL-2.0,PSF-2.0,Unicode-3.0,Python-2.0,Unlicense,CC0-1.0,0BSD,Apache-1.1,BSD-3-Clause-Clear"
```

The allow-list is the shared house list; its wider entries (MPL-2.0,
PSF-2.0, Unicode-3.0, Unlicense, CC0-1.0, 0BSD, Apache-1.1,
BSD-3-Clause-Clear) carry the python lockfile's dependency licenses, so
one list runs identically in every folder's CI and runner.

Remedy: bump or replace the flagged dependency. License violations must be
resolved or justified in review; the osv-scanner exit codes carry the
verdict. Measured wall time: seconds (network-bound, advisory DB cached).
THE GATE IS TESTED: a seeded package-lock.json with lodash 4.17.4 fails
with five GHSA advisories; adding pm2 (AGPL-3.0) fails the license gate:

```text
| https://osv.dev/GHSA-fvqr-27wr-82fm | 6.5  | npm | lodash | 4.17.4 | 4.17.5 | package-lock.json |
advisories exit code: 1
| AGPL-3.0 | npm | pm2 | 5.1.0 | package-lock.json |
license exit code: 130
```

### Hygiene — own-artifact linting (shellcheck, shfmt, yamllint, actionlint)

The repository's own shell scripts and workflow files are linted with the
same severity as its code: shellcheck (v0.11.0), shfmt -d (v3.14.0),
yamllint (v1.38.0, config in the repo-root `.yamllint.yaml`), and
actionlint (v1.7.12) on every workflow file, including the per-folder ci.yml
templates.

```bash
for sh in $(git ls-files "*.sh"); do shellcheck "$sh"; done
for sh in $(git ls-files "*.sh"); do shfmt -d "$sh"; done
yamllint ./.github/workflows/*.yml ./*/ci.yml
actionlint ./.github/workflows/*.yml ./*/ci.yml
```

Remedy: fix the script or the workflow; yamllint deviations carry reasons in
`.yamllint.yaml`. Measured wall time: 0.2s. THE GATE IS TESTED: a clean tree
exits 0 (after fixing the findings this gate itself caught: an unguarded
rm -rf and shfmt formatting); seeded violations fail:

```text
shellcheck: SC2086 on the seeded unquoted variable (exit 1)
yamllint: proof-seed.yaml:2 syntax error (exit 1)
```

### Hygiene — unused dependencies (deptry)

`deptry` compares the imports the code makes against the dependencies
`pyproject.toml` declares (`[project.dependencies]`): a dependency declared
but never imported is the failing case (deptry 0.25.1, pinned in ci.yml;
config in the `[tool.deptry]` table of pyproject.toml, which keeps every
default and records the rule set inline).

```bash
deptry .
```

Remedy: remove the dependency, or import it where the code uses it; a real
exception goes in `[tool.deptry.per_rule_ignores]` with a reason. Measured
wall time: 0.08s on the template fixture. THE GATE IS TESTED: the template
project as-is exits 0 ("Success! No dependency issues found.", and a fixture
that declares and imports `click` also exits 0); a seeded dependency no
module imports fails:

```text
pyproject.toml: DEP002 'httpx' defined as a dependency but not used in the codebase
Found 1 dependency issue.
```

### Hygiene — dead code (vulture)

`vulture` reports names the scan cannot see referenced: a function, class,
method, or variable defined but never called is the failing case (vulture
2.16, pinned in ci.yml; `min_confidence = 60` in the `[tool.vulture]` table
of pyproject.toml keeps every category vulture can report). The scan covers
the shipped package plus `vulture-allowlist.py`; tests stay out on purpose —
pytest fixtures and marks are injected dynamically, so a test scan reads as
false positives.

```bash
vulture your_package vulture-allowlist.py
```

Noise measurement on the template fixture (the step the task requires before
shipping): on a fixture of two modules and two tests, the only finding was a
genuinely unused import, and after the fixture used it, the clean run found
nothing. The allowlist is the noise valve: one reference per line, each with
a reason, empty by design. Remedy: delete the dead code; if the name is used
dynamically, add it to `vulture-allowlist.py` with a reason. Measured wall
time: 0.03s on the template fixture. THE GATE IS TESTED: the clean fixture
exits 0; a seeded uncalled function fails (exit 3):

```text
your_package/core.py:16: unused function 'helper_unused' (60% confidence)
```

### Architecture — import layers (import-linter)

`.importlinter` carries the contracts import-linter checks: a `layers`
contract (api above core, so core must never import api) and a `forbidden`
contract (shipped code must not import pytest). Layers wear parentheses, so
a fresh skeleton with only `__init__.py` passes and each layer wakes up when
its module appears; a cycle inside the covered layers needs an upward import,
so the layers contract is also the cycle gate for the covered modules
(import-linter 2.15, pinned in ci.yml; every contract rule carries its
reason in the config).

Covered paths in the proof: `your_package`, `your_package.api`,
`your_package.core`, and the `your_package -> pytest` edge. The seeded
forbidden import sits inside `your_package.core`, a covered module.

```bash
lint-imports
```

Remedy: move the import, or justify a new contracted exception in that
contract's `ignore_imports` with a reason. Measured wall time: 0.09s on the
template fixture. THE GATE IS TESTED: the bare skeleton (only `__init__.py`)
exits 0 with both contracts KEPT, and the fixture with api and core modules
also exits 0; a seeded upward import fails (exit 1):

```text
Layers import only downwards BROKEN

your_package.core is not allowed to import your_package.api:

- your_package.core -> your_package.api (l.3)
```

### Hygiene — lockfile integrity (hash-pinned installs)

`requirements-lock.txt` pins the full install set with sha256 hashes
(generated from `requirements.in` with pip-tools). The gate installs it with
`--require-hashes`, so any missing or wrong hash fails (pip 25.x docs).

```bash
pip install --require-hashes --dry-run -r requirements-lock.txt
```

Remedy: regenerate the lock with pip-compile and commit it with the version
bumps; never add a package without its hash. Measured wall time: 6.6s for
the compile, seconds for the dry-run install. THE GATE IS TESTED: a clean
lockfile exits 0; a lockfile missing one hash fails:

```text
ERROR: In --require-hashes mode, all requirements must have their versions
pinned with == and a hash. Hash checking failed.
```

### Tests — mutation testing (mutmut, scheduled nightly)

`mutmut` mutates the shipped package (operators, comparisons, literals) and
runs the test suite against each mutant: a mutant the tests do not kill is a
behavior the suite never pinned down (mutmut 3.8.0, pinned in mutation.yml —
the scheduled workflow, not the PR path). Config lives in the
`[tool.mutmut]` table of pyproject.toml: `source_paths` carries the package
name, and `pytest_add_cli_args = ["-o", "addopts="]` strips the coverage
gate from mutmut's internal pytest runs — the cov addopts would run the 95%
gate against the mutated trampolines inside `mutants/` and fail stats
collection before any mutant is tested ("failed to collect stats. runner
returned 1", recorded from the first run).

The score floor is 85, checked from `mutmut export-cicd-stats` (the
documented stats export): `mutmut run` exits 0 even with survivors, so the
floor is a separate step reading `killed/total` from the stats JSON.

```bash
mutmut run
mutmut export-cicd-stats
python3 -c "import json, sys; s = json.load(open('mutants/mutmut-cicd-stats.json')); score = 100 * s['killed'] // s['total']; print('mutation score %d%% (killed %d/%d, floor 85)' % (score, s['killed'], s['total'])); sys.exit(0 if score >= 85 else 1)"
```

The floor reason, from the first measured run on the template fixture:
15/17 killed = 88%. The two survivors are equivalent mutants — `clamp`
returns the bound itself at the boundary, so mutating `value < low` to
`value <= low` cannot change behavior. A floor at 100% would fail on
mutants only a code restructure can remove, so the floor sits just under
the equivalent-mutant headroom, and any genuinely untested code drops the
score below it. Remedy: add a test that kills the surviving mutant.

Why nightly: a mutation run multiplies the test suite by the mutant count,
so it cannot sit between a commit and a merge; the scheduled run keeps the
score visible every night without blocking merges. `run-gates.sh` and the
PR `ci.yml` deliberately exclude it. Trade-off accepted: a mutant that
survives up to a day before the nightly run flags it.

Visibility note: the nightly run's only failure signal is GitHub's
scheduled-run notification, which goes to the single account that created
or last edited the cron; scheduled workflows are also auto-disabled after
about 60 days of repo inactivity. Keep Actions notifications on for that
account and re-run via `gh workflow run mutation` if the nightly has not
fired recently.

Measured wall time: 0.7s for a full run (17 mutants) on the template
fixture. THE GATE IS TESTED: the clean fixture exits 0 (score 88% >= 85); a
seeded function with no test drops the score below the floor and the floor
step exits 1:

```text
mutation score 78% (killed 15/19, floor 85)
```

### Formatter

`ruff format --check .`. The formatter and the lint ignore list are
coordinated by construction: with this config `ruff format` runs
warning-free (its incompatible-rule warning is the tripwire), and
`[tool.ruff.format] docstring-code-format = true` gives docstring examples
the same guarantees as code.

CI uploads the `coverage.xml` pytest-cov writes (cobertura format) to
Coveralls (`coverallsapp/github-action@v2`, free for public repos on the
built-in GITHUB_TOKEN), so the free badge
(`coveralls.io/github/OWNER/REPO/badge.svg`) shows the real number on
every commit, red builds included. The init skill
inserts the badge line into the new repository's README.

## Commands

```bash
./run-gates.sh              # run every gate below, in parallel
pip install "ruff==0.16.6" "mypy==2.3.1" "pytest==9.1.1" "pytest-cov==7.1.0" "coverage[toml]==7.16.0" "deptry==0.25.1" "vulture==2.16" "import-linter==2.15" "mutmut==3.8.0"
ruff check .           # lint + docstring gate
ruff format --check .  # format gate
mypy .                 # type gate
pytest                 # tests + the coverage gate (fail_under = 95, branch = true)
deptry .               # unused-dependency gate
vulture your_package vulture-allowlist.py  # dead-code gate
lint-imports           # import-layer and cycle gate
mutmut run; mutmut export-cicd-stats; python3 -c "import json, sys; s = json.load(open('mutants/mutmut-cicd-stats.json')); score = 100 * s['killed'] // s['total']; print('mutation score %d%% (killed %d/%d, floor 85)' % (score, s['killed'], s['total'])); sys.exit(0 if score >= 85 else 1)"  # nightly mutation-score gate (mutation.yml), not part of run-gates.sh
```

Runner-CI parity: 19 runner entries <-> 19 CI gate steps (4 language gates + 15 hygiene steps; the Coveralls upload and the tool installs are not gates). The runner deliberately
excludes the nightly mutation gate (mutation.yml), so its absence there is
the documented decision, not a miss.

## Trade-offs ("strict but staying usable")

- CI tool installs: the pinned prebuilt binaries are checksum-verified
  where upstream publishes checksums (lychee, gitleaks, osv-scanner,
  actionlint, cargo-deny) and release-tag-pinned where none is published
  (typos, shellcheck, shfmt, cargo-mutants) — the residual risk is
  recorded in the install block and reviewed on every pin bump.
- `select = ["ALL"]` rotates with the pin: a bump may turn on a new family
  that fires loudly. The response is in the ledger, not a reflex delete —
  fix it, or ignore it with a reason; an entry with a dead reason gets
  removed on the next review (house rule 2).
- EM101/EM102 force the `msg = "..."; raise ValueError(msg)` shape on every
  raise. That is the workable half of the TRY003 trade: one lint instead of
  a class-per-message religion, and the message variable keeps tracebacks
  and tests able to match on it.
- Tests run with the doc bar off and assurance rules on: names document
  cases, but RUF100, DTZ, ANN coverage requirements remain. If a repo's
  tests need more relief, it goes in the same `per-file-ignores` table with
  a reason — never as a global ignore.
- `preview = false` is the deliberate refusal of ruff's nursery: preview
  churns both the rule set and the formatter style within the same pin, and
  the baseline prefers a stable surface that only moves when the pin moves.
- `warn_unreachable` prints "Statement is unreachable" on type-analysis
  dead code; mypy documents exact silences (raises, `assert False`, NoReturn
  calls) to keep it spurious-free, and when a platform branch truly splits
  the flow, `# type: ignore[unreachable]` with a reason beats dropping the
  flag.
- Initializing onto a large existing codebase: the D bar can fire hundreds
  of times on docstrings that would have been name-restatements. Budget the
  writing pass, or per-file-ignores the legacy modules with a dated reason —
  never a global ignore of D.

### Accepted gaps — signals no gate in this stack can catch

Stated as current facts, not a plan: nothing below is enforced today, and
each entry names what changes the answer.

- Cognitive complexity. No rule in ruff or mypy computes it (ruff's rule
  index has no cognitive-complexity rule; mypy type-checks, it does not
  score readability). What changes the answer: ruff shipping a stable
  cognitive-complexity rule at a non-preview pin — the TypeScript baseline
  runs exactly that check through eslint-plugin-sonarjs.
- Nesting-depth caps. Ruff has no nesting-depth rule (the `nestif`-style
  signal) and mypy does not count nesting. What changes the answer: a
  nesting-depth rule in ruff's stable set.
- Repeated literal promoted to a constant. PLR2004 only flags magic values
  used in comparisons; a string repeated across branches is invisible to
  the ruff/mypy surface. What changes the answer: a repeated-literal rule
  in ruff (the `goconst`-style check).
- Interface and class-size caps. Ruff's size family is stable for functions
  (PLR0911–PLR0915) but the class-side cap (PLR0906, too many public
  methods) is preview-only, and preview stays off by the baseline's own
  rule. What changes the answer: PLR0906 graduating to stable.
- Assertion-less tests. Nothing static here detects a test whose body runs
  no assertion — it passes vacuously. The nightly mutation run covers the
  signal instead: an untested behavior survives as a mutant and fails the
  mutation-score floor (see the mutation-testing section).
- Refused families, not gaps: coupling/cohesion dashboards and
  Halstead/Maintainability-Index/NPath were reviewed and refused — they are
  not accepted gaps and must not be built (`tasks/expand-lint-gates/notes/refusal-decisions.md` records the reasons).

## The init skill

`init-python-repo/` initializes a new Python repository with all of this.
Install: `scripts/install-skills.sh` (or copy the folder to
`~/.agents/skills/`). The templates are byte-identical copies —
`scripts/verify-sync.sh` fails if they drift. The skill adapts exactly two
placeholders (project name and `--cov=<your_package>`), runs every gate,
and fails loudly rather than leaving a gate quietly missing.
