#!/usr/bin/env python3
"""Targeted yamllint auto-fix for ESPHome configs in this repo.

Fixes the legacy violations carried by 0_DEV/ and 2_PROD/ device YAMLs:
- braces: too many spaces inside    `{ x }` → `{x}`
- brackets: too many spaces inside  `[ x ]` → `[x]`
- comments: missing starting space  `#text` → `# text` (incl. `#!` → `# !`)
- comments: too few spaces before   `key: val # c` → `key: val  # c`
- commas: too many spaces after     `, x,  y` → `, x, y`

Skips block scalars (`lambda: |-`, `|+`, `>`, etc.) so C++ braces/brackets
inside lambdas are untouched.

Usage:
    python3 tools/yamllint_fix.py 0_DEV/<file>.yaml [more files...]

After running, verify with:
    pre-commit run yamllint --files <file>.yaml
    esphome -s ... config <file>.yaml   # ensure config still resolves

Created during 2026-05-09 esp35 migration session. See
memory/project_yamllint_legacy_violations.md for context.
"""
import re
import sys


def fix_file(path: str) -> None:
    with open(path) as f:
        lines = f.readlines()

    out_lines = []
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.lstrip()

        # Detect block scalar header (e.g., `lambda: |-`, `lambda: |`)
        m_block = re.match(r'^(\s*)([^:]+): *[|>][-+]?\s*$', line)
        if m_block:
            header_indent = len(m_block.group(1))
            out_lines.append(line)
            i += 1
            # Copy block scalar content verbatim until dedent
            while i < len(lines):
                content_line = lines[i]
                if content_line.strip() == '':
                    out_lines.append(content_line)
                    i += 1
                    continue
                content_indent = len(content_line) - len(content_line.lstrip())
                if content_indent <= header_indent:
                    break
                out_lines.append(content_line)
                i += 1
            continue

        new_line = line.rstrip('\n')

        # Flow-mapping braces: `{ ` → `{`, ` }` → `}`
        new_line = re.sub(r'\{ +', '{', new_line)
        new_line = re.sub(r' +\}', '}', new_line)

        # Flow-sequence brackets: `[ ` → `[`, ` ]` → `]`
        new_line = re.sub(r'\[ +', '[', new_line)
        new_line = re.sub(r' +\]', ']', new_line)

        # Multiple spaces after comma → single space
        new_line = re.sub(r',  +', ', ', new_line)

        # Pure comment line normalization
        if stripped.startswith('#'):
            # `<indent>#!text` → `<indent># !text` (preserve emphasis)
            m_bang = re.match(r'^(\s*)#!(.*)$', new_line)
            if m_bang:
                new_line = f"{m_bang.group(1)}# !{m_bang.group(2)}"
            else:
                # `<indent>#text` → `<indent># text`
                m_pure = re.match(r'^(\s*)#(?![ #])(.*)$', new_line)
                if m_pure:
                    new_line = f"{m_pure.group(1)}# {m_pure.group(2)}"
        else:
            # Inline comment: ensure 2 spaces before `#` and 1 space after
            m_inline = re.search(r'^(.*\S) +#(?![!])(.*)$', new_line)
            if m_inline:
                code = m_inline.group(1)
                text = m_inline.group(2)
                if text and not text.startswith(' '):
                    text = ' ' + text
                new_line = f"{code}  #{text}"

        out_lines.append(new_line + '\n')
        i += 1

    with open(path, 'w') as f:
        f.writelines(out_lines)

    print(f"Fixed: {path}")


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("usage: yamllint_fix.py <file.yaml> [file2.yaml ...]", file=sys.stderr)
        sys.exit(2)
    for arg in sys.argv[1:]:
        fix_file(arg)
