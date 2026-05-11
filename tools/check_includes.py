#!/usr/bin/env python3
"""Pre-commit hook: verify every `!include <path>` reference in a YAML file
resolves to an existing file with a case-exact path component match.

Catches two regressions this repo has historically suffered:
- BACKLOG #2: ~139 case-mismatch `!include` references that work on macOS
  (case-insensitive FS) but break on Linux/CI/Docker (case-sensitive).
- BACKLOG #3: `!include` referring to a file that never existed in repo.

Skips lines that are comments (anything after the first `#` on the line is
stripped before parsing).
"""
from __future__ import annotations

import os
import re
import sys
from pathlib import Path

# Matches: !include <path>  OR  !include {file: <path>, ...}
RE_SIMPLE = re.compile(r"!include\s+([^\s{][^\s,}\"']*)")
RE_WRAPPED = re.compile(r"!include\s*\{\s*file:\s*([^\s,}\"']+)")


def strip_comment(line: str) -> str:
    """Remove `# ...` comment tail (naively — fine for YAML lines)."""
    in_single = in_double = False
    for i, ch in enumerate(line):
        if ch == "'" and not in_double:
            in_single = not in_single
        elif ch == '"' and not in_single:
            in_double = not in_double
        elif ch == "#" and not in_single and not in_double:
            return line[:i]
    return line


def case_exact_check(repo_root: Path, full: Path) -> str | None:
    """Walk `full` path component-by-component from `repo_root`, verifying
    each segment matches the on-disk casing exactly.

    Returns an error string on mismatch, else None.
    """
    try:
        rel = full.resolve().relative_to(repo_root.resolve())
    except ValueError:
        # Path resolves outside repo — skip case check
        return None
    cur = repo_root
    for part in rel.parts:
        try:
            listing = os.listdir(cur)
        except (FileNotFoundError, NotADirectoryError):
            return f"path component does not exist: {cur}/{part}"
        if part not in listing:
            # Find case-insensitive match for a helpful error
            ci = [n for n in listing if n.lower() == part.lower()]
            if ci:
                return f"case mismatch: referenced '{part}', actual '{ci[0]}' in {cur}"
            return f"path component not found: '{part}' in {cur}"
        cur = cur / part
    return None


def check_file(filepath: Path, repo_root: Path) -> list[str]:
    errors: list[str] = []
    base = filepath.parent
    with filepath.open("r", encoding="utf-8") as f:
        for lineno, raw in enumerate(f, 1):
            line = strip_comment(raw)
            for regex in (RE_SIMPLE, RE_WRAPPED):
                for m in regex.finditer(line):
                    inc = m.group(1).strip(" \"'")
                    if not inc:
                        continue
                    full = (base / inc).resolve()
                    if not full.exists():
                        errors.append(
                            f"{filepath}:{lineno}: !include path does not "
                            f"exist: {inc} (resolved: {full})"
                        )
                        continue
                    case_err = case_exact_check(repo_root, full)
                    if case_err:
                        errors.append(
                            f"{filepath}:{lineno}: !include {inc}: {case_err}"
                        )
    return errors


def is_skipped(path: Path) -> bool:
    """Skip `.esphome/`, `build/`, `deprecated/` and symlinks.

    `.esphome/` and `build/` are caches. `deprecated/` holds old
    non-modular configs kept for reference — their `!include` paths
    pre-date the current modular layout and are intentionally stale.
    Symlinks (e.g. `0_DEV/secrets.yaml -> ../secrets.yaml`) are not
    source files.
    """
    if ".esphome" in path.parts or "build" in path.parts:
        return True
    if "deprecated" in path.parts:
        return True
    if path.is_symlink():
        return True
    # `.yml` extension is a deliberate marker for scripts known not to
    # compile (AGENTS.md "File Naming Conventions"). Their references may
    # be intentionally stale — exclude from validation.
    if path.suffix == ".yml":
        return True
    return False


def main(argv: list[str]) -> int:
    repo_root = Path(__file__).resolve().parent.parent
    all_errors: list[str] = []
    for arg in argv[1:]:
        path = Path(arg)
        if not path.exists() or is_skipped(path):
            continue
        all_errors.extend(check_file(path, repo_root))
    for err in all_errors:
        print(err)
    return 1 if all_errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
