#!/usr/bin/env python3
"""Pre-commit hook: bump `version: "YYYYMMDD"` substitution in staged ESPHome
YAML files to today's date.

Targets BACKLOG #26 — manual `version:` field drifts behind actual edits.
This hook sweeps any staged device YAML containing a `  version: "<8-digit>"`
substitution line and rewrites the digits to today's date. Files without
the pattern, or files whose value already matches today, are left untouched.

Exits non-zero when any file is modified, so pre-commit prompts the user to
re-stage the change.
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
