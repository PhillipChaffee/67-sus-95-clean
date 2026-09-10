---
name: add-language
description: >-
  Adds a new language folder to the strictest-setups reference repository: researches
  that language's strictest workable lint, type-check, docstring/comment, and
  code-coverage enforcement stack from official docs, authors the folder with canonical
  config files, an installable init skill, and a >=95% coverage gate, validates the
  configs, and updates the root README. Use when the user asks to add a language to the
  strictest-setups repo or to extend the polyglot lint baseline with another language.
---

# Goal

Add one new language folder to the strictest-setups repository with the same
guarantees the existing folders have: strict-but-workable lint, types, docs,
comments, and a machine-enforced 95% coverage gate. Read the repo root
`README.md` first — its "house rules" section is the contract every folder
meets, and the invariant it names (a folder is not merged until its coverage
gate provably fails a build under 95%) is the acceptance test for this skill
too.

# Inputs you need

The language name and the parent repo. If the target language is already
present, this skill is not applicable — say so and stop.

# Workflow

## 1. Research (only from official sources, and only what you can cite)

For the target language, find and pin down — from official documentation pages,
never from blog lore:

1. The strictest lint/config the language's dominant linter supports that a
   normal clean repository can build with. Read the linter's rule index and
   configuration reference until you can state, per rule group, whether the
   repo should enable, ignore, or document it.
2. The strict type-checking surface (the `--strict` / `strictest` equivalent),
   including the few flags that sit beyond the flagship switch and the two or
   three that are known-flaky and therefore documented instead of enabled.
3. Comment and docstring enforcement: the doc-checking ruleset (e.g. a
   pydocstyle-equivalent, a doc-comment plugin, an exported-symbol rule). If
   the language has NO mainstream checker for inline comment prose, verify
   that lack in the docs and record it in the folder README rather than
   inventing a threat.
4. The coverage gate: the tool that produces coverage, its fail-under switch
   or the command-line idiom that reproduces one, and whether branch coverage
   exists (record the answer either way).
5. The formatter and its check-mode flag, and the pinned-toolchain mechanism.

Every claim you author into the folder must trace to a URL you fetched. If you
cannot verify a key, mark it UNVERIFIED in the README rather than guessing.

## 2. Author the folder

Create `<slug>/` in the repo root (slug = how the toolchain names the language,
lowercase):

- `README.md` — the table of what is enforced and why, following the structure
  of the existing folders: one section per enforcement layer, a trade-offs
  section ("strict but staying usable": the rules known to be noisy are named
  and justified), and the exact commands a developer runs, in the same shape
  as the other folders.
- Canonical config files at the folder root — real, complete, syntactically
  valid; each non-default choice carries its reason in an adjacent comment or
  the README.
- `.github/workflows/ci.yml` — the gates running exactly the README commands
  (lint with warnings fatal where the toolchain supports deny, type check,
  format check, tests, and the coverage gate that fails under 95).
- `init-<slug>-repo/` — an installable skill for initializing a new
  repository in this language: `SKILL.md` with the standard frontmatter rules
  (`name` = the folder name, lowercase-and-hyphens; `description` third person,
  under 1024 chars), and `templates/` carrying byte-identical copies of every
  canonical config file. The SKILL.md must instruct the agent to (a) copy
  templates, (b) substitute the project name only where marked, (c) run all
  README gates before the first commit, and (d) fail loudly rather than
  proceed when a tool chain cannot be installed.

Add the language's row to the root README table and the layout example if the
tree description changes.

## 3. Validate, then verify the invariant

1. `scripts/verify-sync.sh` — add the new template pairings to its explicit
   list first, then run it; it must pair every canonical config with a
   byte-identical template copy.
2. Parse every structured config you wrote (TOML with `tomllib`, YAML with a
   YAML parser, JSON with `json.tool`); a syntax error is authoring failure.
3. Parse each `SKILL.md`'s frontmatter the way the house does: yaml-safe-load
   the block between the first two `---` lines, assert `name` matches the
   directory, and `description` is a non-empty string of 1024 characters or
   fewer.
4. PROVE the coverage gate: build a scratch example (in `/tmp`, outside the
   repo) tiny enough to instrument quickly, run the folder's coverage command
   against it, and demonstrate (a) it passes at ≥95% and (b) it FAILS when
   coverage drops below 95 — e.g. by deleting a comment-line or function to
   push uncovered statements up. Record the two command outputs in the folder
   README's coverage section. A gate that has never failed is unverified.
5. Run a final `git -C <repo> status` review and make sure no scratch files
   leaked into the tree.

## 4. Stop lines

- If the language has no coverage tooling at all, stop and surface that fact
  to the user instead of authoring a folder without the gate.
- If two rule sets contradict (as eslint's stylistic rules can), keep the
  documented-contradictions section of the README truthful: enumerate what you
  refused to enable and why.
- Never delete or "tidy" existing folders to make room; this skill only adds.
