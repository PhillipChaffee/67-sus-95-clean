# T03 (rust) suppression + TODO gates

Depends on: T02 (shares the CI file) · Touched:
`rust/Cargo.toml.example` ( `[workspace.lints]` restriction picks),
`rust/ci.yml` + template copy, `rust/README.md` (lint
table), templates, make sure that-sync list

## Steps

1. Add `allow_attributes_without_reason` to the restriction-picks shortlist
   with its reason in the lint table (house rule: an allow without a why is
   the bug). Make sure that it fires with the pinned clippy. Adjust the README lint
   table row.
2. Add the uniform TODO gate as a CI step: a grep (or ripgrep) step that
   fails on banned markers ( `TODO`, `FIXME`: match the policy the other
   folders adopt). Document exactly what counts and why. This is the rust
   half of the uniform TODO policy.
3. Check the interplay: `#[expect]` with a reason stays the documented
   suppression path `expect` over `allow` is already the house pattern. Say so next to the new pick.
4. README: update the lint table and add the TODO policy note.
5. Prove: a seeded bare `#[allow(...)]` fails clippy. A seeded `// TODO`
   fails the CI step. Record both outputs.
6. verify-sync.sh + repo lint. Commit.

## Acceptance criteria

Positive:

- [ ] `cargo clippy ... -D warnings` fails on an unreasoned allow.
- [ ] The TODO CI step fails on a seeded `// TODO`.
- [ ] The restriction-picks table lists the new pick with its reason.

Negative:

- [ ] No restriction pick added without a reason.
- [ ] The TODO step has an escape hatch only where the policy defines one
      (documented), not an ad-hoc ignore.
- [ ] verify-sync.sh passes.
