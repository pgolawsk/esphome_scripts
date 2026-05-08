# upgrade/

This directory manages the ESPHome version upgrade lifecycle for this repo.

## Files

| File | Purpose | When to update |
|------|---------|---------------|
| `COMPONENTS.md` | Snapshot of all ESPHome components used across the repo (platforms, sensors, integrations, architecture patterns) | Every upgrade cycle — update version table and snapshot date |
| `ESPHOME_<version>.md` | Impact analysis for a specific ESPHome version: breaking changes, new features (rated by relevance), devices to reflash | Create one per upgrade; mark devices done as you flash them |
| `SOP_upgrade.md` | Step-by-step upgrade procedure (8 steps: check → upgrade → update docs → grep checks → compile → flash → verify → mark done) | Update if the process changes |

## Typical workflow

```bash
# 1. Check if upgrade is needed
bash check_esphome_version.sh

# 2. Upgrade
bash check_esphome_version.sh --auto

# 3. Open upgrade/ and follow SOP_upgrade.md
```

The current impact file is **`ESPHOME_2026.4.5.md`** (covers 2026.2 → 2026.4.5).
Start there to see which devices still need reflashing.

## Convention

- One `ESPHOME_<version>.md` file per upgrade. Keep the last 2–3; delete older ones.
- `COMPONENTS.md` is a single living file — overwrite, don't version it.
