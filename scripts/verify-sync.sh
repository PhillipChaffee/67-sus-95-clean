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
rust/Cargo.toml.example			rust/init-rust-repo/templates/Cargo.toml.example
rust/clippy.toml			rust/init-rust-repo/templates/clippy.toml
rust/rust-toolchain.toml		rust/init-rust-repo/templates/rust-toolchain.toml
rust/rustfmt.toml			rust/init-rust-repo/templates/rustfmt.toml
rust/ci.yml				rust/init-rust-repo/templates/ci.yml
rust/AGENTS.md.example			rust/init-rust-repo/templates/AGENTS.md.example
python/pyproject.toml			python/init-python-repo/templates/pyproject.toml
python/ci.yml				python/init-python-repo/templates/ci.yml
typescript/tsconfig.json		typescript/init-typescript-repo/templates/tsconfig.json
typescript/eslint.config.mjs		typescript/init-typescript-repo/templates/eslint.config.mjs
typescript/vitest.config.ts		typescript/init-typescript-repo/templates/vitest.config.ts
typescript/package.json			typescript/init-typescript-repo/templates/package.json
typescript/.prettierignore		typescript/init-typescript-repo/templates/.prettierignore
typescript/ci.yml			typescript/init-typescript-repo/templates/ci.yml
go/.golangci.yml			go/init-go-repo/templates/.golangci.yml
go/ci.yml				go/init-go-repo/templates/ci.yml
go/coverage-gate.sh			go/init-go-repo/templates/coverage-gate.sh
rust/run-gates.sh			rust/init-rust-repo/templates/run-gates.sh
python/run-gates.sh			python/init-python-repo/templates/run-gates.sh
typescript/run-gates.sh			typescript/init-typescript-repo/templates/run-gates.sh
go/run-gates.sh			go/init-go-repo/templates/run-gates.sh
.markdownlint-cli2.jsonc			python/init-python-repo/templates/.markdownlint-cli2.jsonc
.markdownlint-cli2.jsonc			rust/init-rust-repo/templates/.markdownlint-cli2.jsonc
.markdownlint-cli2.jsonc			go/init-go-repo/templates/.markdownlint-cli2.jsonc
.markdownlint-cli2.jsonc			typescript/init-typescript-repo/templates/.markdownlint-cli2.jsonc
lychee.toml			python/init-python-repo/templates/lychee.toml
lychee.toml			rust/init-rust-repo/templates/lychee.toml
lychee.toml			go/init-go-repo/templates/lychee.toml
lychee.toml			typescript/init-typescript-repo/templates/lychee.toml
.gitleaks.toml			python/init-python-repo/templates/.gitleaks.toml
.gitleaks.toml			rust/init-rust-repo/templates/.gitleaks.toml
.gitleaks.toml			go/init-go-repo/templates/.gitleaks.toml
.gitleaks.toml			typescript/init-typescript-repo/templates/.gitleaks.toml
.jscpd.json			python/init-python-repo/templates/.jscpd.json
.jscpd.json			rust/init-rust-repo/templates/.jscpd.json
.jscpd.json			go/init-go-repo/templates/.jscpd.json
.jscpd.json			typescript/init-typescript-repo/templates/.jscpd.json
.yamllint.yaml			python/init-python-repo/templates/.yamllint.yaml
.yamllint.yaml			rust/init-rust-repo/templates/.yamllint.yaml
.yamllint.yaml			go/init-go-repo/templates/.yamllint.yaml
.yamllint.yaml			typescript/init-typescript-repo/templates/.yamllint.yaml
PAIRINGS
)
exit $fail
