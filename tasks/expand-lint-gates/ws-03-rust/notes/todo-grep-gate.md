# Todo grep gate

The uniform TODO policy for rust is a grep-based CI step (no mainstream  clippy lint exists for TODO markers). Keep it simple and explicit: a CI step that greps for the banned markers and fails on any hit. Document what counts as a banned marker (e.g. `TODO`, `FIXME`) and why.
