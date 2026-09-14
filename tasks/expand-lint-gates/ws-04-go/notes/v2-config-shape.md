# V2 config shape

golangci-lint v2 config shape differs from v1: the `version: "2"` quoted  key matters, linters live in a `linters:` section with `settings:` per linter. Follow the existing `.golangci.yml` style.
