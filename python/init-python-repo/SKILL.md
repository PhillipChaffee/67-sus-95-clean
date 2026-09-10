---
name: init-python-repo
description: >-
  Initializes a new Python repository with the strictest workable enforcement
  stack: ruff with ALL-minus-documented-ignores plus Google-convention docstring
  enforcement (D), mypy --strict with warn_unreachable beyond it, ruff format,
  and pytest-cov with branch coverage gated at >=95% by fail_under. Use when the
  user asks to initialize, bootstrap, or set up a new Python project or
  repository with strict linting, docstring requirements, type checking, and a
  code-coverage gate.
---

# Initialize a strict Python repository

Sets up a brand-new Python repository so that `ruff check .` fails on any
lint or docstring violation (including every undocumented module, class,
method, function, or package), `mypy .` runs `--strict` plus
`warn_unreachable`, `ruff format --check .` is clean, and `pytest` fails the
build when branch coverage drops under 95%. Read this repo's
`python/README.md` for the reasoning behind every piece; the steps below
assume that reasoning and only record the work.

# Preconditions

- A Python 3.12+ interpreter with `python -m venv` and network access to
  PyPI for the five pinned tools.
- You know the project name and it is valid in both places it appears
  (PEP 508 `name`, importable package directory).

# Steps

1. Create the skeleton: the package directory `<name>/` with `__init__.py`,
   a `tests/` directory, and a `.venv` (`python -m venv .venv`).
2. Install the pinned tools into the venv:
   `pip install "ruff==0.16.6" "mypy==2.3.1" "pytest==9.1.1"
   "pytest-cov==7.1.0" "coverage[toml]==7.16.0"` — the exact pins
   `ci.yml` re-installs.
3. Copy the templates from this skill's `templates/` directory into the
   repository root: `pyproject.toml -> pyproject.toml`,
   `ci.yml -> .github/workflows/ci.yml` (create the directory). These are
   byte-copies of the canonical files.
4. Adapt exactly two placeholders, both spelling the same token so
   `grep -rn your_package` finds them: `[project] name` and the
   `--cov=<your_package>` token in
   `[tool.pytest.ini_options] addopts`. Rename the package directory to
   match. `pytest` fails loudly until the substitution is done — that is
   the template working as intended.
5. Run every gate and make each one pass or fail for a known, acceptable
   reason, in this order:
   - `ruff check .`
   - `ruff format --check .`
   - `mypy .`
   - `pytest`
   The D ruleset is this language's missing-docs equivalent: an undocumented
   module, class, method, function, or package FAILS `ruff check`; write the
   doc (what the signature cannot say), or scope a targeted
   `per-file-ignores` entry with a reason — never delete the rule to pass
   the build. Test files get the tests bar from the template's
   `per-file-ignores`; if the repo's layout differs, adapt the glob there.
6. Prove the coverage gate the way `python/README.md` records it: all tests
   passing must exit 0, and temporarily commenting ONE test out must fail
   `pytest` with `FAIL Required test coverage of 95.0% not reached` and a
   nonzero exit. Restore the test afterward.
7. Commit everything in one bootstrap commit (message style is the repo's
   choice from here on).

# Gates

- After step 5, ALL four commands run green (or a documented, pre-existing
  decision explains any red), and step 6 showed the gate failing under 95%.
- `scripts/verify-sync.sh` in this reference repo still passes: templates
  must be edits of the canonical files, not independent forks.
- If pip cannot install a pinned tool, or a gate cannot run in this
  environment, STOP and report the tooling failure; do not proceed with the
  gate quietly missing.
