#!/usr/bin/env python3
"""Pre-commit hook: verify every `<<:` merge-key line is followed by either
`!include <path>` or `*<anchor>` (the only legitimate RHS for the override-
by-order pattern this repo relies on).

Catches malformed merge-key chains that ESPHome's loader silently mishandles
because PyYAML treats `<<:` differently from regular keys (cross-ref
AGENTS.md "YAML Override Mechanism").
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

RE_MERGE_KEY = re.compile(r"^(\s*)<<:\s*(.*?)\s*$")


def check_file(filepath: Path) -> list[str]:
    errors: list[str] = []
    with filepath.open("r", encoding="utf-8") as f:
        for lineno, raw in enumerate(f, 1):
            line = raw.rstrip("\n")
            # Skip commented-out merge keys
            stripped = line.lstrip()
            if stripped.startswith("#"):
                continue
            m = RE_MERGE_KEY.match(line)
            if not m:
                continue
            rhs = m.group(2)
            # Strip trailing inline comment
            if "#" in rhs:
                rhs = rhs[: rhs.index("#")].rstrip()
            # Empty RHS — `<<:` followed by indented mapping on next lines.
            # YAML-valid but not used in this repo's override-by-order pattern;
            # warn so reviewers notice.
            if not rhs:
                errors.append(
                    f"{filepath}:{lineno}: `<<:` with empty RHS (block-style "
                    f"merge) — repo convention is inline `<<: !include path` "
                    f"or `<<: *anchor`"
                )
                continue
            if rhs.startswith("!include") or rhs.startswith("*"):
                continue
            errors.append(
                f"{filepath}:{lineno}: `<<:` RHS must start with `!include` "
                f"or `*anchor`, got: {rhs!r}"
            )
    return errors


def is_skipped(path: Path) -> bool:
    if ".esphome" in path.parts or "build" in path.parts:
        return True
    if "deprecated" in path.parts:
        return True
    if path.is_symlink():
        return True
    if path.suffix == ".yml":
        return True
    return False


def main(argv: list[str]) -> int:
    all_errors: list[str] = []
    for arg in argv[1:]:
        path = Path(arg)
        if not path.exists() or is_skipped(path):
            continue
        all_errors.extend(check_file(path))
    for err in all_errors:
        print(err)
    return 1 if all_errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
