#!/usr/bin/env bash
# Runs every PR-blocking gate from this folder's README, in parallel.
# Keep this gate list in sync with the CI steps in ci.yml. Mutation
# testing is nightly only, so it is deliberately not here.
#
# The gate commands below are opaque strings that run_gates.sh evaluates
# at runtime; shellcheck sees them out of context here.
# shellcheck disable=SC2016,SC2027,SC2086,SC2154

# Requires the pinned golangci-lint binary: see the README install
# command (go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.13.2).

set -u -o pipefail

log_dir="$(mktemp -d)"
trap 'rm -rf "$log_dir"' EXIT

names=()
cmds=()
add() {
	names+=("$1")
	cmds+=("$2")
}
add "schema" "golangci-lint config verify"
add "build" "go build ./..."
add "tidy" "go mod tidy -diff"
add "format" "golangci-lint fmt --diff"
add "vet" "go vet ./..."
add "lint" "golangci-lint run"
add "tests" "go test ./..."
add "coverage" "./coverage-gate.sh"

add "spell-check" "typos"
add "markdown-lint" "markdownlint-cli2 \"**/*.md\""
add "link-check" "lychee --no-progress ."
add "secret-scan" "gitleaks detect --no-git --redact"
add "duplication" "jscpd"
add "advisories" "osv-scanner scan -r ."
add "license-check" "osv-scanner scan -r . --licenses=MIT,Apache-2.0,ISC,BSD-3-Clause,BSD-2-Clause,MPL-2.0,PSF-2.0,Unicode-3.0,Python-2.0,Unlicense,CC0-1.0,0BSD,Apache-1.1,BSD-3-Clause-Clear,LGPL-3.0-only,BlueOak-1.0.0,CC-BY-3.0"
add "shell-lint" 'for sh in $(git ls-files "*.sh"); do shellcheck "$sh"; done'
add "shell-format" 'for sh in $(git ls-files "*.sh"); do shfmt -d "$sh"; done'
add "workflow-yaml-lint" "yamllint ./.github/workflows/*.yml $(ls ./*/ci.yml ./*/mutation.yml 2>/dev/null)"
add "workflow-lint" "actionlint ./.github/workflows/*.yml $(ls ./*/ci.yml ./*/mutation.yml 2>/dev/null)"
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
