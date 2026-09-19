#!/usr/bin/env bash
# Runs every PR-blocking gate from this folder's README, in parallel.
# Keep this gate list in sync with the CI steps in ci.yml.
#
# The gate commands below are opaque strings that run_gates.sh evaluates
# at runtime; shellcheck sees them out of context here.
# shellcheck disable=SC2016,SC2027,SC2086,SC2154

# Requires the pinned tools on PATH: shellcheck 0.11.0, shfmt 3.14.0,
# ast-grep 0.45.3, kcov v42's prebuilt binary (see ci.yml's install block
# for the exact download commands and sha256 digests).

set -u -o pipefail

log_dir="$(mktemp -d)"
trap 'rm -rf "$log_dir"' EXIT

names=()
cmds=()
add() {
	names+=("$1")
	cmds+=("$2")
}
add "shell-lint" 'for sh in $(git ls-files "*.sh"); do shellcheck "$sh"; done'
add "shell-format" "shfmt -d ."
add "tests" "./test/run_tests.sh"
add "coverage" "./coverage-gate.sh"
add "file-length" "./effective-lines-gate.sh"
add "doc-header" 'for sh in $(git ls-files "*.sh"); do ast-grep scan --rule ast-grep/header-comment.yml "$sh"; done'
# The pattern is quote-split ("TOD""O") because this runner is itself a
# *.sh file the gate scans: unsplit, the literal regex bytes here would
# self-match and the gate could never go green. Options come BEFORE the
# pattern: git parses a post-pattern --untracked as a revision (exit 128,
# verified on git 2.50.1), and --no-recurse-submodules neutralizes a local
# submodule.recurse=true that would otherwise reject --untracked. The
# captured exit code makes the gate fail-closed: git grep exits 0 on
# matches, 1 on none, and errors above that — only 1 may pass.
add "todo-policy" 'rc=0; git grep --untracked --no-recurse-submodules -nE "TOD""O|FIX""ME" -- "*.sh" || rc=$?; test "$rc" -eq 1'

add "spell-check" "typos"
add "markdown-lint" 'markdownlint-cli2 "**/*.md"'
add "link-check" "lychee --no-progress ."
add "secret-scan" "gitleaks detect --no-git --redact"
add "duplication" "jscpd"
add "workflow-yaml-lint" "yamllint ./.github/workflows/*.yml $(find . -mindepth 2 -maxdepth 2 \( -name 'ci.yml' -o -name 'mutation.yml' \) -not -path './.github/*' | tr '\n' ' ')"
add "workflow-lint" "actionlint ./.github/workflows/*.yml $(find . -mindepth 2 -maxdepth 2 \( -name 'ci.yml' -o -name 'mutation.yml' \) -not -path './.github/*' | tr '\n' ' ')"
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
