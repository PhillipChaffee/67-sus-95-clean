# Note: the gates effort's refusals (decided, do not re-open)

Recorded by the wayfinder effort "enforce cognitive complexity, file length,
and doc-substance gates across all five languages" (map #12; decisions #16–#20,
implementations #21–#25). Each refusal carries evidence from a measured
session; the tickets hold the full detail. These are not gaps to fill.

## 1. Cyclomatic complexity — removed family-wide (decided, do not re-open)

Not a refusal but a consolidation with refusal consequences. Cognitive
complexity (SonarSource spec) is the only complexity metric this baseline
gates. Removed at the same time: go `cyclop`; python C901 plus
PLR0911/PLR0912 (PLR0915 stays as the per-function size
axis, the python precedent); typescript eslint `complexity`. Clippy's
`cognitive_complexity` restriction lint is refused as a spec gate for rust
(see 5). Thresholds stay per-tool because no two tools implement the spec
identically; the shared anchor is Sonar's own S3776 default, 15.

## 2. Banned-filler phrase gates — refused in every language

A gate against "filler phrases" in doc comments ("simply", "just", "note
that", …) fails the gate bar at the definition step, not the tooling step:
there is no canonical, maintained list of filler phrases with consistent
semantics, so no threshold or rule can be stated precisely. Research #14
swept the space; nothing implements it anywhere.

## 3. pydoclint — refused for python doc completeness

The research's central claim ("pydoclint's DOC101 closes the proven D417
no-Args hole") was falsified empirically at pydoclint 0.9.1:

- At the researched invocation, `skip-checking-short-docstrings` defaults
  True and pydoclint is silent on section-less docstrings (one-line and
  multi-line) — it adds nothing over ruff D417 there.
- Forcing `skip-short=False` closes the hole but is stricter than Google:
  DOC101 fires on one-line docstrings Google §3.8.3 explicitly permits, and
  DOC201 demands Returns sections beyond Google's exemptions.
- The researched `--arg-type-hints-in-signature=False` trips DOC108 on
  every annotated function, contradicting this repo's annotation mandate.

Neither mode is Google-faithful; ruff `D` (google) stays the doc gate.
What changes the answer: a stable ruff DOC rule that audits section-less
docstrings, or the hole biting in practice. Proven fallback recorded in
python/README.md: pydoclint with `--skip-checking-short-docstrings=False`
(deliberately stricter than Google) plus corrected flags.

## 4. omen as the shell cognitive gate — refused after the measured probe

Decision #19 adopted panbanda/omen 4.30.0 adopt-if-measured, with binding
spec-fidelity probes and the documented refusal as ratified fallback. The
probe FAILED at the pin (shell/README.md records the measured output):

- Top-level code outside functions is never scored — and shell gate scripts
  are mostly top-level, so the gate would be near-vacuous.
- `&&`/`||` sequences never count in bash's cognitive walker.

The fallback fired; the refusal stands, amended with the probe record.
What changes the answer: an omen version that scores top-level bash code
(or ships a script mode) and prices `&&`/`||` per the whitepaper — the
threshold would stay 15.

## 5. clippy `cognitive_complexity` — refused as a spec gate (rust)

Clippy has the lint (`cognitive-complexity-threshold`, restriction, default
25), but it self-disclaims in source — "left in `restriction` so as to not
mislead users into using this lint as a measurement tool" — and counts flat
decisions only, so it cannot carry the SonarSource spec. It stays enabled as
a size-axis hint, never as the complexity gate. What changes the answer:
clippy re-spec'ing the lint against the whitepaper.

## 6. shdoc-ng — refused for shell doc annotations

An opt-in `## @tag` annotation validator that never flags undocumented
functions; adopting it would impose an annotation convention the narrow
doc-gate reopen never demanded (v0.9.1, four months old at decision time).
The adopted shell doc gate is mechanical presence only (ast-grep
header-comment rule); prose quality stays refused (nine-category sweep in
decision #19 found no shell comment-prose checker anywhere).

## 7. Go doc completeness layer — refused as a category error

Canonical go doc comments are prose-first (go.dev/doc/comment); a
python-style args/returns completeness gate has nothing structurally to
enumerate, so "completeness" is a category error for go, not a gap. No tool
anywhere enforces "not just restating the signature" for go either. Go's
mechanical ceiling is revive `exported` + godoclint `deprecated` +
`no-unused-link` (decision #16). What changes the answer: a maintained go
doc checker that mechanically audits prose substance without inventing a
section convention.

## 8. Commented-out-code detection for go — refused (experimental)

golangci-lint's implementation is experimental at the pinned version; the
gate bar requires a maintained, stable check. python (ruff) and typescript
(eslint) already run it; rust and shell have no implementation (absence, not
refusal). What changes the answer: the go rule stabilizing upstream.

## 9. TypeScript jsdoc completeness rules — four refused

From decision #20, on the researched ceiling:

- `require-property-description` — beyond the ceiling for this baseline.
- `require-throws` — optional behavior docs; beyond the ceiling.
- `require-description-complete-sentence` — noisier; python already refused
  sentence-completeness enforcement under Google convention (consistency).
- `require-example` — noise (research verdict).

## 10. Shell function-comment presence (Google §4.2) — not adopted

Header-comment presence (§4.1) is gated via ast-grep house rules; per-
function comments are not. Noise risk dominates on one-liner helper
functions. Escape hatch per the refusal-note convention: if code review
repeatedly catches one specific failure, add that single rule with recorded
incidents.

## The bar to reopen

Every refusal above is evidence-based, not permanent. The shared bar stands
(`tasks/expand-lint-gates/notes/refusal-decisions.md`): precise definition,
maintained tool, binary gate, proven failure, stated remedy. Each section's
"what changes the answer" line names the specific datum that reopens it; a
candidate that clears the bar re-enters through a decision ticket, not a
silent config bump.
