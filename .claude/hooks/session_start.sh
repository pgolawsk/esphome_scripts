#!/usr/bin/env bash
# SessionStart hook: surface pending work at the top of the session.
#   - agents_inbox/  : Larry's task briefs awaiting FLUX
#   - BACKLOG.md     : top-N open items, ranked by severity then effort

set -euo pipefail
cd "$(dirname "$0")/../.."

echo "## agents_inbox/ (live only, archive/ hidden)"
inbox_empty=1
if [ -d agents_inbox ]; then
  for f in agents_inbox/*; do
    [ -f "$f" ] || continue
    echo "- $(basename "$f")"
    inbox_empty=0
  done
fi
[ "$inbox_empty" = "1" ] && echo "_(empty)_"
echo

echo "## BACKLOG.md — rekomendacje co dalej"
python3 - <<'PY'
import re
from pathlib import Path

text = Path("BACKLOG.md").read_text()
items = []
pattern = r'^### (\d+)\. (.+?)$\n(.*?)(?=^### \d+\.|^## |\Z)'
for m in re.finditer(pattern, text, re.M | re.S):
    num, title, body = m.group(1), m.group(2), m.group(3)
    if "**Status:** ✅ done" in body:
        continue
    sev = re.search(r'\*\*Severity:\*\*\s*(\w+)', body)
    eff = re.search(r'\*\*Effort:\*\*\s*(\w+)', body)
    items.append({
        "num": int(num),
        "title": title.strip(),
        "sev": sev.group(1) if sev else "?",
        "eff": eff.group(1) if eff else "?",
    })

sev_rank = {"Important": 0, "Notable": 1, "Minor": 2, "Cosmetic": 3}
eff_rank = {"S": 0, "M": 1, "L": 2}
items.sort(key=lambda x: (
    sev_rank.get(x["sev"], 9),
    eff_rank.get(x["eff"], 9),
    x["num"],
))

total = len(items)
print(f"_{total} otwartych itemów. Top 5 (sev → effort → numer):_")
print()
for it in items[:5]:
    print(f"- **#{it['num']}** [{it['sev']}/{it['eff']}] {it['title']}")
PY
