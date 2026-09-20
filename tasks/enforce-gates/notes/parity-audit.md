# Note: cross-language parity audit (merge readiness)

The final artifact of the wayfinder effort "enforce cognitive complexity,
file length, and doc-substance gates across all five languages" (map #12).
One table, per language: cognitive threshold, file-length mechanism and
threshold, doc-substance bundle, proof links. Decisions #16–#20; the five
implementation PRs #27–#31 are merged to main.

| language | cognitive gate (threshold 15) | file-length gate | doc-substance bundle | proofs |
| --- | --- | --- | --- | --- |
| go | `gocognit` min-complexity 15 (Sonar's Go S3776 default); `cyclop` removed | house `go/token` effective-lines script, max 750; generated files exempt, tests included | revive `exported` presence floor + godoclint `deprecated` + `no-unused-link` (`default: none`); completeness refused (prose-first godoc) | `go/README.md` §Linting, §Documentation & comments, §File length; [PR #27](https://github.com/PhillipChaffee/67-sus-95-clean/pull/27) |
| python | complexipy 8.0.1, threshold 15 in `[tool.complexipy]` (Sonar S3776 anchor); C901/PLR0911/PLR0912 removed, PLR0915 kept | house ast+tokenize effective-lines script, max 1000; docstrings excluded, fail-closed | ruff `D` (google) stands; pydoclint refused (fix claim falsified empirically) | `python/README.md` §Complexity, §Documentation, §File length; [PR #28](https://github.com/PhillipChaffee/67-sus-95-clean/pull/28) |
| rust | arborist-cli 0.2.1 `--threshold 15 --exceeds-only`, pinned `--locked` (Sonar S3776 anchor; 17/23 spec probes) | house stdlib effective-lines counter, max 1000; attributes count as code, fail-closed | rustdoc/rustc doc lints at ceiling + clippy `doc_paragraphs_missing_punctuation` (adopt-if-clean passed: zero findings on the clean run) | `rust/README.md` §Complexity, §Documentation, §File length; [PR #29](https://github.com/PhillipChaffee/67-sus-95-clean/pull/29) |
| shell | refused — omen 4.30.0 probed and failed (top-level code unscored, boolean short-circuit operators uncounted); ratified fallback fired | house heredoc-state-machine effective-lines script, max 200; tests included, no exemptions | ast-grep 0.45.3 header-comment presence rule (shebang skipped); prose checker refused (nine-category sweep) | `shell/README.md` §Complexity, §File length, §Documentation & comments; [PR #30](https://github.com/PhillipChaffee/67-sus-95-clean/pull/30) |
| typescript | sonarjs `cognitive-complexity` max 15 (Sonar's own default; eslint `complexity` removed) | eslint `max-lines` 300 effective (`skipBlankLines` + `skipComments`), repo-wide, no test carve-out | jsdoc `require-param-description` + `require-returns-description` + `informative-docs` at documented defaults; four completeness rules refused | `typescript/README.md` §Linting, §Documentation & comments; [PR #31](https://github.com/PhillipChaffee/67-sus-95-clean/pull/31) |

## Parity readings

- **Cognitive**: four languages gate at the Sonar S3776 default anchor of 15
  (gocognit, complexipy, arborist, sonarjs); shell is the documented refusal
  after the omen probe failed. Thresholds are per-tool by decision — no two
  tools implement the spec identically — but every adopted gate anchors at
  15.
- **File length**: one mechanism family-wide — effective lines (blank and
  comment lines don't count) — with per-language house scripts except
  typescript, which keeps native eslint `max-lines` at the same effective-
  line definition. Thresholds are human-ratified per language (750, 1000,
  1000, 300, 200), no uniformity assumption.
- **Doc substance**: every language gates its strongest mechanical slice;
  four languages refused their completeness candidates for measured reasons
  (pydoclint, godoc category error, rust at ceiling, shell prose sweep),
  and banned-filler phrase gates are refused everywhere.
- **Proofs**: every gate is binary and proven to fail in-tree (seeded
  failures in each folder README); `scripts/verify-sync.sh` pairs all five
  new gate files with their templates and passes.

## Merge readiness

The five implementation PRs are merged. This effort's cross-cutting PR —
root README house rules and stack table, these notes, the refusal record —
is the last change; once merged, the destination is reached and the map
closes with no fog and no open tickets.
