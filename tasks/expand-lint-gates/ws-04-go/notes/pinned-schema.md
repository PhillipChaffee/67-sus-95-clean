# Pinned schema

The folder's contract: the pinned golangci-lint binary is the enforcement  tool. Every new linter name must be verified against the pinned v2 binary's schema ( `golangci-lint config verify`: a made-up settings key is rejected). Do not trust memory. Run the make sure that command.
