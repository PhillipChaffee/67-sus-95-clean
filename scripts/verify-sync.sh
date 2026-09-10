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
done < <(cat <<'PAIRINGS'
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
PAIRINGS
)
exit $fail