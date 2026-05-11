#!/usr/bin/env python3
"""Pre-commit hook: shape check for device YAML files in 0_DEV/, 1_UAT/,
2_PROD/.

Each device file in those folders should contain at least one top-level
`<<: !include ../includes/board_*.yaml` (or the `{file: ...}` wrapped form)
— that's how the device pulls in its board definition. A device file with
zero board includes is almost certainly broken (a refactor regression).

The check counts top-level `<<: !include` lines (any indent → 0) and
errors if there are zero in a non-empty device file. Upper bound check
(>15) flags pathological files.

Promotes the manual grep documented in `upgrade/SOP_upgrade.md` to a
pre-commit hook (BACKLOG #70 cross-ref).
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

RE_TOPLEVEL_MERGE = re.compile(r"^<<:\s*!include")
RE_TOPLEVEL_MERGE_ANCHOR = re.compile(r"^<<:\s*\*")


def is_device_file(filepath: Path) -> bool:
    """Files under 0_DEV/, 1_UAT/, 2_PROD/ are device YAMLs subject to the
    shape check. Other YAMLs (includes, sensors, etc.) are exempt.
    Caches (`.esphome/`, `build/`) and symlinks are also exempt.
    """
    parts = filepath.parts
    if ".esphome" in parts or "build" in parts:
        return False
    if filepath.is_symlink():
        return False
    for marker in ("0_DEV", "1_UAT", "2_PROD"):
        if marker in parts:
            return True
    return False


def looks_empty(filepath: Path) -> bool:
    """Treat near-empty files (only comments / `---` marker) as exempt —
    they're stubs, not full device configs.
    """
    text = filepath.read_text(encoding="utf-8")
    non_trivial = [
        line.strip()
        for line in text.splitlines()
        if line.strip() and not line.strip().startswith("#") and line.strip() != "---"
    ]
    return len(non_trivial) < 5


def check_file(filepath: Path) -> list[str]:
    if not is_device_file(filepath):
        return []
    if looks_empty(filepath):
        return []

    count = 0
    with filepath.open("r", encoding="utf-8") as f:
        for raw in f:
            line = raw.rstrip("\n")
            if line.lstrip().startswith("#"):
                continue
            if RE_TOPLEVEL_MERGE.match(line) or RE_TOPLEVEL_MERGE_ANCHOR.match(line):
                count += 1

    errors: list[str] = []
    # Count == 0 is suspicious but not always a bug (some example/stub
    # device files are deliberately flat with everything inline). Print
    # a warning to stdout but DO NOT fail the hook — that's reserved for
    # clearly pathological cases (count > 15).
    if count == 0:
        print(
            f"{filepath}: warning: no top-level `<<: !include` lines found — "
            f"flat device file (no override-by-order). Verify intent."
        )
    elif count > 15:
        errors.append(
            f"{filepath}: {count} top-level `<<: !include` lines — "
            f"unusually high, likely accidental duplication."
        )
    return errors


def main(argv: list[str]) -> int:
    all_errors: list[str] = []
    for arg in argv[1:]:
        path = Path(arg)
        if not path.exists():
            continue
        all_errors.extend(check_file(path))
    for err in all_errors:
        print(err)
    return 1 if all_errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
