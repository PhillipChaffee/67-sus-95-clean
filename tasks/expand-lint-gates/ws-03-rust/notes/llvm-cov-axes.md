# Llvm cov axes

Coverage: the current gate is `cargo llvm-cov --fail-under-lines 95`.  llvm-cov reports region and function coverage too. Make sure that what fail-under switches actually exist at the pinned cargo-llvm-cov version before promising an axis. If a region/branch fail-under switch does not exist, record the limit like the go folder records statement-only coverage.
