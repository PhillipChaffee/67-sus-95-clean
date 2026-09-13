#!/usr/bin/env bash
# Runs every PR-blocking gate from this folder's README, in parallel.
# Keep this gate list in sync with the CI steps in ci.yml. Mutation
# testing is nightly only, so it is deliberately not here.

# Requires node_modules. Run npm ci once first if it is missing.

set -u -o pipefail

log_dir="$(mktemp -d)"
trap 'rm -rf "$log_dir"' EXIT

names=()
cmds=()
add() { names+=("$1"); cmds+=("$2"); }
add "format" "npm run format:check"
add "types" "npm run typecheck"
add "lint" "npm run lint"
add "tests+coverage" "npm test"

add "spell-check" "typos"
add "markdown-lint" "markdownlint-cli2 \"**/*.md\""
add "link-check" "lychee --no-progress ."
add "secret-scan" "gitleaks detect --no-git --redact"
add "duplication" "jscpd"
add "advisories" "osv-scanner scan -r ."
add "license-check" "osv-scanner scan -r . --licenses=\"MIT,Apache-2.0,ISC,BSD-3-Clause,BSD-2-Clause\""
add "shell-lint" "for sh in $(git ls-files "*.sh"); do shellcheck "$sh"; done"
add "shell-format" "for sh in $(git ls-files "*.sh"); do shfmt -d "$sh"; done"
add "workflow-yaml-lint" "yamllint .github/workflows/ */ci.yml"
add "workflow-lint" "actionlint .github/workflows/ */ci.yml"
for i in "${!names[@]}"; do
  name="${names[$i]}"
  cmd="${cmds[$i]}"
  (
    if eval "$cmd" >"$log_dir/$name.log" 2>&1; then
      echo "PASS  $name" >"$log_dir/$name.status"
    else
      echo "FAIL  $name" >"$log_dir/$name.status"
      printf '%s\n' "--- $name output ---" >>"$log_dir/failures.log"
      cat "$log_dir/$name.log" >>"$log_dir/failures.log"
    fi
  ) &
done
wait

cat "$log_dir"/*.status 2>/dev/null
if [ -f "$log_dir/failures.log" ]; then
  echo "=== failing gate output ==="
  cat "$log_dir/failures.log"
  exit 1
fi
echo "all gates pass"
