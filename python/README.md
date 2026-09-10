# python/ — the Python strict baseline

The stack below is verified against the pinned tools, not folklore: every
ignore carries its reason, and the coverage gate was proven to fail a build
under 95% (both runs are recorded in the coverage section). Pin of record:
ruff 0.16.6, mypy 2.3.1, pytest 9.1.1, pytest-cov 7.1.0, coverage 7.16.0.

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
  - **Noise rules** (CPY001, TRY003, TD002, FIX002): a copyright stamp is a
    legal-layer policy, not a code-quality signal; TRY003 demands a custom
    exception class per message while EM101/EM102 keep the message
    discipline instead; TD002 demands TODO authorship git blame already
    owns; FIX002 says "resolve the issue" while TD001/TD003/TD004 already
    govern the same comment.
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

Machine: the D ruleset above and its per-file test carve-out; TODO tags are
governed by TD001/TD003/TD004 (an issue link is required, an author is not);
RUF100 fails the build on any unused `# noqa` so suppression cannot rot.

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
pip install "ruff==0.16.6" "mypy==2.3.1" "pytest==9.1.1" "pytest-cov==7.1.0" "coverage[toml]==7.16.0"
ruff check .           # lint + docstring gate
ruff format --check .  # format gate
mypy .                 # type gate
pytest                 # tests + the coverage gate (fail_under = 95, branch = true)
```

## Trade-offs ("strict but staying usable")

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

## The init skill

`init-python-repo/` initializes a new Python repository with all of this.
Install: `scripts/install-skills.sh` (or copy the folder to
`~/.agents/skills/`). The templates are byte-identical copies —
`scripts/verify-sync.sh` fails if they drift. The skill adapts exactly two
placeholders (project name and `--cov=<your_package>`), runs every gate,
and fails loudly rather than leaving a gate quietly missing.
