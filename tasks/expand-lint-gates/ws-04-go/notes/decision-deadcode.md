# Decision: refuse the x/tools deadcode gate (go)

Tested empirically, not from docs:

- `go run golang.org/x/tools/cmd/deadcode@v0.40.0 ./...` on the go fixture:
  reports unreachable functions (api/api.go:10 Classify, api/api.go:25
  Clamp, and the seeded files), **exit code 0**.
- `go run golang.org/x/tools/cmd/deadcode@v0.50.0 ./...` (the current
  latest, 2026-09-08): same report, **exit code 0**.

The tool is a reporter, not a gate: it has no nonzero-exit-on-findings
mode at either tested version, and the task forbids a wrapper script that
fakes a nonzero exit. Refused.

Go dead-code detection stays covered by the `unused` staticcheck-family
linter (already enabled in `default: standard`), which fails the build on
unused unexported functions. Unreachable *exported* functions remain an
accepted gap (see the go README trade-offs).
