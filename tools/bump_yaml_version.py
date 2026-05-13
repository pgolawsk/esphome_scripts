#!/usr/bin/env python3
"""Manual helper: bump `version: "YYYYMMDD"` substitution in ESPHome device
YAML files to today's date.

Semantics: `version:` should reflect the date of the last **functional change**
(new sensor, new option, behavior change) — NOT cosmetic refactoring,
version-history appends, formatting fixes, or substitution boilerplate
cleanup. Run this script ONLY when committing a functional change. Do not
register it as a pre-commit hook (an earlier attempt was reverted because
auto-bump on every commit destroyed the semantics).

Usage: `python3 tools/bump_yaml_version.py <yaml_path> [<yaml_path>...]`

Behavior: matches `^(  version: ")(\\d{8})(".*)$` per line, replaces the
digits with `date.today().strftime("%Y%m%d")`. Files without the pattern,
or files whose value already matches today, are left untouched. Prints the
list of modified files; exits 1 when anything changed, 0 otherwise.
"""
from __future__ import annotations

import argparse
import datetime
import re
import sys
from pathlib import Path

PATTERN = re.compile(r'^(  version: ")(\d{8})(".*)$', re.MULTILINE)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("files", nargs="+")
    args = parser.parse_args()
    today = datetime.date.today().strftime("%Y%m%d")
    modified: list[str] = []
    for path in args.files:
        p = Path(path)
        if not p.exists():
            continue
        text = p.read_text()

        def repl(m: re.Match[str]) -> str:
            if m.group(2) == today:
                return m.group(0)
            return f"{m.group(1)}{today}{m.group(3)}"

        new_text, n = PATTERN.subn(repl, text)
        if n > 0 and new_text != text:
            p.write_text(new_text)
            modified.append(path)
    if modified:
        print(f"bumped version field to {today} in: " + " ".join(modified))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
