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
.typos.toml			python/init-python-repo/templates/.typos.toml
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
.typos.toml			rust/init-rust-repo/templates/.typos.toml
.markdownlint-cli2.jsonc			rust/init-rust-repo/templates/.markdownlint-cli2.jsonc
lychee.toml			rust/init-rust-repo/templates/lychee.toml
.gitleaks.toml			rust/init-rust-repo/templates/.gitleaks.toml
.jscpd.json			rust/init-rust-repo/templates/.jscpd.json
.yamllint.yaml			rust/init-rust-repo/templates/.yamllint.yaml
go/ci.yml			go/init-go-repo/templates/ci.yml
go/run-gates.sh			go/init-go-repo/templates/run-gates.sh
.typos.toml			go/init-go-repo/templates/.typos.toml
.markdownlint-cli2.jsonc			go/init-go-repo/templates/.markdownlint-cli2.jsonc
lychee.toml			go/init-go-repo/templates/lychee.toml
.gitleaks.toml			go/init-go-repo/templates/.gitleaks.toml
.jscpd.json			go/init-go-repo/templates/.jscpd.json
.yamllint.yaml			go/init-go-repo/templates/.yamllint.yaml
typescript/ci.yml			typescript/init-typescript-repo/templates/ci.yml
typescript/run-gates.sh			typescript/init-typescript-repo/templates/run-gates.sh
.typos.toml			typescript/init-typescript-repo/templates/.typos.toml
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
exit $fail
