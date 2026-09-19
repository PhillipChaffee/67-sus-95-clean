#!/usr/bin/env bash
#
# File-length gate for a strict Go repository: fails when any Go file
# exceeds the maximum effective-line count.
#
# "Effective lines" counts a physical line unless it is blank, is a
# whole-line comment, or lies inside a /* */ block — the same definition
# eslint gives TypeScript's max-lines (skipBlankLines + skipComments). The
# counting is a go/token scanner with ScanComments run from a temporary
# stdlib-only module (compiled at gate time by the go toolchain this repo
# already requires), so a "//" inside a raw string literal is never
# mistaken for a comment and a block comment's interior lines are never
# mistaken for code. If a file cannot be scanned cleanly it counts every
# non-blank line: fail closed, never silently.
#
# Exemption: a file whose section before the package clause carries the
# canonical "// Code generated ... DO NOT EDIT." header line (go.dev/s/
# generatedcode) is exempt — the house principle that generated code is
# not reviewed here. The scan walks exactly what the go toolchain sees:
# directories `go build ./...` skips (dot-prefixed, underscore-prefixed,
# vendor, testdata) are skipped here, and _test.go files are capped
# identically — no test carve-out (a table too big for the cap is data
# and belongs in a fixture).
#
# Threshold 750: Sonar's Go S104 default (GO_DEFAULT_FILE_LINE_MAX = 750),
# the only directly citable effective-lines number for Go. Raise it only
# with a written reason here, never silently. Remedy for a violation:
# split the file by responsibility (funlen stays as the per-function
# axis).
#
# Usage: run from the repository (module) root: ./effective-lines-gate.sh
set -u -o pipefail

readonly max_effective_lines=750

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

root="$(pwd -P)"

# The scanner is embedded: the gate carries its own tool, needs no module
# files, no network (stdlib only), and adds no Go source to the repository
# it gates — so it cannot trip the linters, coverage, or dependency gates
# it runs beside.
cat >"$tmp/main.go" <<'EOF'
// Effective-lines counter for the house file-length gate. A line counts
// unless it is blank, is a whole-line comment, or lies inside a block
// comment; go/token's scanner with ScanComments supplies the comment
// spans. Usage: effective-lines <max> <root>. Exit 0 clean, 1 violations,
// 2 tooling or usage error.
package main

import (
	"fmt"
	"go/scanner"
	"go/token"
	"io/fs"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

// The canonical generated-file header (go.dev/s/generatedcode): a physical
// line in the section before the package clause.
var generatedLine = regexp.MustCompile(`^// Code generated .* DO NOT EDIT\.$`)

type span struct{ lo, hi int }

func main() { os.Exit(run()) }

func run() int {
	if len(os.Args) != 3 {
		fmt.Fprintln(os.Stderr, "usage: effective-lines <max-effective-lines> <root>")
		return 2
	}
	max, err := atoi(os.Args[1])
	if err != nil || max < 1 {
		fmt.Fprintln(os.Stderr, "effective-lines: <max> must be a positive integer")
		return 2
	}
	root, err := filepath.Abs(os.Args[2])
	if err != nil {
		fmt.Fprintf(os.Stderr, "effective-lines: bad root: %v\n", err)
		return 2
	}
	violations := 0
	walkErr := filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			name := d.Name()
			if path != root && (strings.HasPrefix(name, ".") || strings.HasPrefix(name, "_") ||
				name == "vendor" || name == "testdata") {
				return filepath.SkipDir
			}
			return nil
		}
		if filepath.Ext(path) != ".go" || !d.Type().IsRegular() {
			return nil
		}
		count, generated, cerr := effectiveLines(path)
		if cerr != nil {
			return err
		}
		if generated {
			return nil
		}
		if count > max {
			violations++
			fmt.Printf("%s: %d effective lines exceeds the maximum of %d\n", path, count, max)
		}
		return nil
	})
	if walkErr != nil {
		fmt.Fprintf(os.Stderr, "effective-lines: walk failed: %v\n", walkErr)
		return 2
	}
	if violations > 0 {
		fmt.Fprintf(os.Stderr, "effective-lines: FAIL — %d file(s) exceed the %d effective-line maximum\n",
			violations, max)
		return 1
	}
	return 0
}

func atoi(s string) (int, error) {
	n := 0
	if s == "" {
		return 0, fmt.Errorf("empty")
	}
	for _, c := range s {
		if c < '0' || c > '9' {
			return 0, fmt.Errorf("not a number: %q", s)
		}
		n = n*10 + int(c-'0')
	}
	return n, nil
}

// lines splits src on '\n'; the final segment is returned even without a
// trailing newline, so every physical line is seen exactly once.
func lines(src []byte) [][]byte {
	var out [][]byte
	start := 0
	for i := 0; i < len(src); i++ {
		if src[i] == '\n' {
			out = append(out, src[start:i])
			start = i + 1
		}
	}
	return append(out, src[start:])
}

func isPackageClause(line []byte) bool {
	return strings.HasPrefix(strings.TrimSpace(string(line)), "package ")
}

func nonSpaceBounds(line []byte) (first, last int) {
	first, last = -1, -1
	for i := 0; i < len(line); i++ {
		if line[i] != ' ' && line[i] != '\t' && line[i] != '\r' {
			if first == -1 {
				first = i
			}
			last = i
		}
	}
	return first, last
}

// insideComment reports whether the whole non-space byte range [first,
// last] of a line lies inside one comment span — a whole-line comment.
func insideComment(spans []span, first, last int) bool {
	if first < 0 || last < 0 {
		return false
	}
	for _, s := range spans {
		if s.lo <= first && last+1 <= s.hi {
			return true
		}
	}
	return false
}

func effectiveLines(path string) (count int, generated bool, err error) {
	src, err := os.ReadFile(path)
	if err != nil {
		return 0, false, err
	}
	// Generated-code exemption: the canonical header line anywhere before
	// the package clause (go.dev/s/generatedcode).
	for _, line := range lines(src) {
		if isPackageClause(line) {
			break
		}
		if generatedLine.Match(line) {
			return 0, true, nil
		}
	}
	fset := token.NewFileSet()
	file := fset.AddFile(path, fset.Base(), len(src))
	var s scanner.Scanner
	var commentSpans []span
	clean := true
	s.Init(file, src, func(_ token.Position, _ string) { clean = false }, scanner.ScanComments)
	for {
		pos, tok, lit := s.Scan()
		if tok == token.EOF {
			break
		}
		if tok == token.COMMENT {
			start := file.Offset(pos)
			commentSpans = append(commentSpans, span{start, start + len(lit)})
		}
	}
	base := 0
	for _, line := range lines(src) {
		if strings.TrimSpace(string(line)) != "" {
			first, last := nonSpaceBounds(line)
			// Fail closed: a file the scanner could not read cleanly
			// counts every non-blank line — comment spans are unreliable
			// there.
			excluded := clean && insideComment(commentSpans, first+base, last+base)
			if !excluded {
				count++
			}
		}
		base += len(line) + 1
	}
	return count, false, nil
}
EOF
printf 'module effective-lines-gate\n\ngo 1.21\n' >"$tmp/go.mod"

(cd "$tmp" && go run . "$max_effective_lines" "$root") >"$tmp/violations.txt" 2>"$tmp/toolerr.txt"
rc=$?

if [ "$rc" -eq 1 ]; then
	sed 's/^/effective-lines: /' "$tmp/violations.txt" >&2
	cat "$tmp/toolerr.txt" >&2
	exit 1
fi
if [ "$rc" -ne 0 ]; then
	echo "effective-lines-gate: FAIL — the scanner could not run; fix the tooling, never skip the gate" >&2
	sed 's/^/  /' "$tmp/toolerr.txt" >&2
	exit 1
fi
echo "effective-lines-gate: PASS — no Go file exceeds ${max_effective_lines} effective lines"
