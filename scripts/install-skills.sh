#!/usr/bin/env bash
# Installs this repo's skills into ~/.agents/skills/, the single location both
# opencode and goose read. Refuses to clobber an existing skill without --force
# so a stale is never silently older than the repo.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
dest="${HOME}/.agents/skills"
mkdir -p "$dest"
force=""
[[ "${1:-}" == "--force" ]] && force="--force"
for skill_dir in rust/init-rust-repo python/init-python-repo typescript/init-typescript-repo go/init-go-repo add-language; do
  name="$(basename "$skill_dir")"
  if [[ -e "$dest/$name" && -z "$force" ]]; then
    echo "SKIP $name (exists; re-run with --force to replace)"
    continue
  fi
  rm -rf "$dest/$name"
  cp -R "$skill_dir" "$dest/$name"
  echo "INSTALLED $name"
done
echo "Done. Re-run scripts/verify-sync.sh after editing any config."
