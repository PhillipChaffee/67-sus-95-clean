"""House gate: fail when a Python file exceeds the maximum line count.

Ruff has no file-length rule, so the gate is a deterministic script that CI
runs and the test suite re-checks. Raise the limit only with a written
reason in the file, never silently.
"""

from __future__ import annotations

import sys
from pathlib import Path

MAX_LINES = 500
EXCLUDED_DIRS = {".venv", ".git", "__pycache__", ".mypy_cache", ".pytest_cache"}


def find_violations(root: Path, max_lines: int = MAX_LINES) -> list[str]:
    """Return one message per Python file in root that exceeds max_lines."""
    violations: list[str] = []
    for path in sorted(root.rglob("*.py")):
        if path.parts and any(part in EXCLUDED_DIRS for part in path.parts):
            continue
        line_count = len(path.read_text().splitlines())
        if line_count > max_lines:
            violations.append(f"{path}: {line_count} lines exceeds the maximum of {max_lines}")
    return violations


def main() -> int:
    """Run the gate from the repository root and exit nonzero on violations."""
    root = Path()
    violations = find_violations(root)
    for message in violations:
        print(message, file=sys.stderr)
    if violations:
        print(
            f"FAIL {len(violations)} file(s) exceed the {MAX_LINES}-line limit",
            file=sys.stderr,
        )
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
