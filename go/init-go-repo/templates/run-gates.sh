#!/usr/bin/env bash
# Runs every PR-blocking gate from this folder's README, in parallel.
# Keep this gate list in sync with the CI steps in ci.yml. Mutation
# testing is nightly only, so it is deliberately not here.

# Requires the pinned golangci-lint binary: see the README install
# command (go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.13.2).

set -u -o pipefail

log_dir="$(mktemp -d)"
trap 'rm -rf "$log_dir"' EXIT

names=()
cmds=()
add() { names+=("$1"); cmds+=("$2"); }
add "schema" "golangci-lint config verify"
add "build" "go build ./..."
add "format" "golangci-lint fmt --diff"
add "vet" "go vet ./..."
add "lint" "golangci-lint run"
add "tests" "go test ./..."
add "coverage" "./coverage-gate.sh"

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
