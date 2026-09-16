#!/usr/bin/env bash
# Fails when a skill's templates/ copy drifts from the canonical config it
# mirrors. One source of truth per config; templates are install-time copies.
# The pairing is explicit because a template need not share the canonical
# file's basename.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
fail=0
while IFS=$'\t' read -r canonical template; do
	if [[ ! -f "$canonical" ]]; then
		echo "MISSING canonical: $canonical"
		fail=1
		continue
	fi
	if [[ ! -f "$template" ]]; then
		echo "MISSING template: $template"
		fail=1
		continue
	fi
	if ! cmp -s "$canonical" "$template"; then
		echo "DRIFTED: $template differs from $canonical"
		fail=1
	fi
done < <(
	cat <<'PAIRINGS'
python/ci.yml			python/init-python-repo/templates/ci.yml
python/run-gates.sh			python/init-python-repo/templates/run-gates.sh
python/.gitignore			python/init-python-repo/templates/.gitignore
python/.importlinter			python/init-python-repo/templates/.importlinter
python/.typos.toml			python/init-python-repo/templates/.typos.toml
.markdownlint-cli2.jsonc			python/init-python-repo/templates/.markdownlint-cli2.jsonc
lychee.toml			python/init-python-repo/templates/lychee.toml
.gitleaks.toml			python/init-python-repo/templates/.gitleaks.toml
.jscpd.json			python/init-python-repo/templates/.jscpd.json
.yamllint.yaml			python/init-python-repo/templates/.yamllint.yaml
rust/Cargo.toml.example			rust/init-rust-repo/templates/Cargo.toml.example
rust/clippy.toml			rust/init-rust-repo/templates/clippy.toml
rust/rust-toolchain.toml			rust/init-rust-repo/templates/rust-toolchain.toml
rust/rustfmt.toml			rust/init-rust-repo/templates/rustfmt.toml
rust/AGENTS.md.example			rust/init-rust-repo/templates/AGENTS.md.example
rust/deny.toml			rust/init-rust-repo/templates/deny.toml
rust/ci.yml			rust/init-rust-repo/templates/ci.yml
rust/run-gates.sh			rust/init-rust-repo/templates/run-gates.sh
rust/mutation.yml			rust/init-rust-repo/templates/mutation.yml
rust/.typos.toml			rust/init-rust-repo/templates/.typos.toml
.markdownlint-cli2.jsonc			rust/init-rust-repo/templates/.markdownlint-cli2.jsonc
lychee.toml			rust/init-rust-repo/templates/lychee.toml
.gitleaks.toml			rust/init-rust-repo/templates/.gitleaks.toml
.jscpd.json			rust/init-rust-repo/templates/.jscpd.json
.yamllint.yaml			rust/init-rust-repo/templates/.yamllint.yaml
go/ci.yml			go/init-go-repo/templates/ci.yml
go/run-gates.sh			go/init-go-repo/templates/run-gates.sh
go/.typos.toml			go/init-go-repo/templates/.typos.toml
.markdownlint-cli2.jsonc			go/init-go-repo/templates/.markdownlint-cli2.jsonc
lychee.toml			go/init-go-repo/templates/lychee.toml
.gitleaks.toml			go/init-go-repo/templates/.gitleaks.toml
.jscpd.json			go/init-go-repo/templates/.jscpd.json
.yamllint.yaml			go/init-go-repo/templates/.yamllint.yaml
typescript/ci.yml			typescript/init-typescript-repo/templates/ci.yml
typescript/run-gates.sh			typescript/init-typescript-repo/templates/run-gates.sh
typescript/.typos.toml			typescript/init-typescript-repo/templates/.typos.toml
.markdownlint-cli2.jsonc			typescript/init-typescript-repo/templates/.markdownlint-cli2.jsonc
lychee.toml			typescript/init-typescript-repo/templates/lychee.toml
.gitleaks.toml			typescript/init-typescript-repo/templates/.gitleaks.toml
.jscpd.json			typescript/init-typescript-repo/templates/.jscpd.json
.yamllint.yaml			typescript/init-typescript-repo/templates/.yamllint.yaml
python/pyproject.toml			python/init-python-repo/templates/pyproject.toml
python/vulture-allowlist.py			python/init-python-repo/templates/vulture-allowlist.py
python/requirements.in			python/init-python-repo/templates/requirements.in
python/requirements-lock.txt			python/init-python-repo/templates/requirements-lock.txt
python/osv-scanner.toml			python/init-python-repo/templates/osv-scanner.toml
python/mutation.yml			python/init-python-repo/templates/mutation.yml
typescript/tsconfig.json			typescript/init-typescript-repo/templates/tsconfig.json
typescript/eslint.config.mjs			typescript/init-typescript-repo/templates/eslint.config.mjs
typescript/knip.jsonc			typescript/init-typescript-repo/templates/knip.jsonc
typescript/.dependency-cruiser.cjs		typescript/init-typescript-repo/templates/.dependency-cruiser.cjs
typescript/vitest.config.ts			typescript/init-typescript-repo/templates/vitest.config.ts
typescript/package.json			typescript/init-typescript-repo/templates/package.json
typescript/.prettierignore			typescript/init-typescript-repo/templates/.prettierignore
go/.golangci.yml			go/init-go-repo/templates/.golangci.yml
go/coverage-gate.sh			go/init-go-repo/templates/coverage-gate.sh
PAIRINGS
)

# Cross-folder drift check: the hygiene install blocks and the license
# allow-list are intentionally shared across the four folder ci.yml files and
# the root dogfood workflow (jscpd ignores those globs and no pairing rows
# cross folders, so nothing else catches one folder's pin bumping while the
# other three lag). Per-folder extras (python's pip tools, rust's cargo-deny)
# are filtered before comparing.
fingerprint() {
	# Per-folder extras are filtered before comparing: python's pip tools
	# (installed from the hash-pinned lock), rust's cargo-deny and cargo-shear
	# downloads, and all pip/npm registry installs (which differ by folder by
	# design).
	awk '/Install pinned hygiene tools/,/Spell check/' "$1" |
		grep -vE 'deptry|vulture|import-linter|DENY_VERSION|cargo-deny|deny\.|denyx|pinned versions|cargo-shear|SHEAR_VERSION|shear\.|pip install|npm install' |
		grep -vE '^[[:space:]]*#' |
		grep -vE '^[[:space:]]*(- name:|- run:|run: \|?)?[[:space:]]*$' |
		sed 's/^[[:space:]]*//' | sort | sha256sum | awk '{print $1}'
}
expected_license='MIT,Apache-2.0,ISC,BSD-3-Clause,BSD-2-Clause,MPL-2.0,PSF-2.0,Unicode-3.0,Python-2.0,Unlicense,CC0-1.0,0BSD,Apache-1.1,BSD-3-Clause-Clear,LGPL-3.0-only,BlueOak-1.0.0,CC-BY-3.0'
for f in .github/workflows/hygiene.yml python/ci.yml rust/ci.yml go/ci.yml typescript/ci.yml; do
	fp="$(fingerprint "$f")"
	if [[ "$fp" != "$(fingerprint .github/workflows/hygiene.yml)" ]]; then
		echo "CROSS-FOLDER DRIFT: $f install block differs from .github/workflows/hygiene.yml"
		fail=1
	fi
	if ! grep -qF "$expected_license" "$f"; then
		echo "CROSS-FOLDER DRIFT: $f does not carry the shared 14-license allow-list"
		fail=1
	fi
done

# Runner drift: the shared hygiene gate entries (same names, same commands)
# must match across the four folder run-gates.sh files; per-language entries
# are filtered out by name.
runner_fingerprint() {
	grep -E '^add "(spell-check|markdown-lint|link-check|secret-scan|duplication|advisories|license-check|shell-lint|shell-format|workflow-yaml-lint|workflow-lint)" ' "$1" |
		sed 's/^[[:space:]]*//' | sort | sha256sum | awk '{print $1}'
}
for f in python/run-gates.sh rust/run-gates.sh go/run-gates.sh typescript/run-gates.sh; do
	if [[ "$(runner_fingerprint "$f")" != "$(runner_fingerprint python/run-gates.sh)" ]]; then
		echo "CROSS-FOLDER DRIFT: $f hygiene gate entries differ from python/run-gates.sh"
		fail=1
	fi
done

exit $fail
