#!/usr/bin/env bash
#
# Coverage gate for a strict Go repository: fails when total statement
# coverage is below 95%.
#
# `go test -coverprofile` writes the profile, `go tool cover -func` prints
# per-package counts plus a `total:` line, and awk compares that total
# against the threshold. A failing `go test` fails the gate too — coverage
# is never reported on an unproven suite.
#
# This is statement coverage only: `go tool cover` counts statements, and
# the Go toolchain ships no branch-coverage mode (see the README's coverage
# section for the consequences). The profile is kept in every path: on
# failure for `go tool cover -html=cover.out`, and on success so the CI's
# Codecov upload step can turn it into the free coverage badge.
#
# Usage: run from the repository (module) root: ./coverage-gate.sh
set -u -o pipefail

readonly required=95
readonly profile=cover.out

if ! go test "-coverprofile=${profile}" -coverpkg=./... ./...; then
	echo "coverage-gate: FAIL — go test failed; profile kept at ${profile} for debugging" >&2
	exit 1
fi

total=$(go tool cover "-func=${profile}" | tail -n 1)
if [[ -z "${total}" ]]; then
	echo "coverage-gate: FAIL — 'go tool cover' produced no total line; profile kept at ${profile}" >&2
	exit 1
fi
pct=$(printf '%s\n' "${total}" | awk '{print $NF}' | tr -d '%')
if [[ -z "${pct}" ]] || ! awk -v got="${pct}" -v need="${required}" 'BEGIN { exit !(got + 0 >= need + 0) }'; then
	echo "coverage-gate: FAIL — total statement coverage is ${pct:-(unreadable)}%, required ${required}%; profile kept at ${profile}" >&2
	exit 1
fi

echo "coverage-gate: PASS — total statement coverage ${pct}% ≥ ${required}% (profile kept at ${profile} for the CI upload)"
