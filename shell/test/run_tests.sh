#!/usr/bin/env bash
# Minimal test runner: sources every library in src/ and runs the
# expectations below. Replace the example assertions with the project's
# tests, keeping the harness (the expect helper, the fail accumulator,
# the trailing exit). coverage-gate.sh runs this script twice — once
# plainly for the exit status, then under kcov for coverage.
set -u -o pipefail
cd "$(dirname "$0")/.." || exit
# The library list is dynamic, so ShellCheck cannot follow the sources
# statically; each library is checked in its own right by the lint gate.
# shellcheck disable=SC1090
for lib in src/*.sh; do
	. "$lib"
done

fail=0
expect() {
	local label="$1"
	shift
	local expected="$1"
	shift
	local got
	got=$("$@")
	if [ "$got" != "$expected" ]; then
		echo "FAIL: $label -> $got (expected $expected)"
		fail=1
	else
		echo "ok: $label == $expected"
	fi
}

expect "greet world" "hello, world" greet world
exit "$fail"
