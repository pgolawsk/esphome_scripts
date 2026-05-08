# SOP: ESPHome Version Upgrade

Procedure for upgrading ESPHome in this repo, updating the component inventory, and reflashing devices.

---

## Overview

This directory contains:
- `COMPONENTS.md` — inventory of all components used in the repo (updated on each upgrade cycle)
- `ESPHOME_<version>.md` — impact analysis for a specific ESPHome version
- `SOP_upgrade.md` — this file

---

## Step 1: Check Current Version

```bash
cd ~/dev/esphome_scripts
source .venv/bin/activate
esphome version
```

Or use the helper script:

```bash
bash check_esphome_version.sh
```

If the installed version matches the latest available: nothing to do.

---

## Step 2: Upgrade ESPHome

```bash
# Activate venv
source .venv/bin/activate

# Upgrade
pip install -U esphome

# Verify
esphome version
```

Or use the helper script with auto mode:

```bash
bash check_esphome_version.sh --auto
```

---

## Step 3: Update COMPONENTS.md

Scan the repo and update `upgrade/COMPONENTS.md` to reflect the current state:

1. Check platforms in use: `grep -r "^esp32:\|^esp8266:" 2_PROD/ --include="*.yaml" -l`
2. Check min_version pins: `grep -rn "esphome_min_version" --include="*.yaml" . | grep -v ".esphome"`
3. Update the **ESPHome Version** table in `COMPONENTS.md`:
   - Set "Installed in `.venv`" to the new version
   - Update "Last used to flash" to the previous version
4. Update the **Snapshot date** field

---

## Step 4: Create Version Impact File

Create `upgrade/ESPHOME_<new_version>.md` (copy from the previous version file as a template).

Research the changelog for the new version:
- Official changelog: `https://esphome.io/changelog/<version>/`
- GitHub releases: `https://github.com/esphome/esphome/releases`

Populate sections:
1. **Breaking Changes** — list anything that requires config edits; include grep commands to find affected files
2. **New Features Worth Exploring** — rate by relevance (★★★ high / ★★ medium / ★ low) based on what this repo actually uses
3. **Positive Fixes** — stability/performance improvements, no action required
4. **Devices to Reflash** — prioritized list with reason

---

## Step 5: Pre-Flight Checks

Before reflashing any device, run the breaking change checks from the new impact file:

```bash
cd ~/dev/esphome_scripts

# Standard checks (update these based on the new impact file)
grep -rn "trigger_id" --include="*.yaml" . | grep -v ".esphome"
grep -rn "FlushResult" --include="*.yaml" . | grep -v ".esphome"
grep -rn "\.raw_state" --include="*.yaml" . | grep -v ".esphome"
```

Fix any matches before proceeding.

---

## Step 6: Compile and Test (Dry Run)

Compile without flashing to catch YAML/config errors:

```bash
esphome compile 2_PROD/<device>.yaml
```

If compile fails: fix the error, re-check breaking changes section.

---

## Step 7: Flash Devices

Flash in priority order from the impact file. Start with lowest-risk devices to validate the process.

```bash
# OTA flash (device must be online)
esphome run 2_PROD/<device>.yaml --device <ip_address>

# USB flash (first-time or recovery)
esphome run 2_PROD/<device>.yaml
```

After each flash:
- Verify device appears in Home Assistant
- Check logs: `esphome logs 2_PROD/<device>.yaml --device <ip_address>`
- Monitor for 2–3 minutes for crashes or reboots

---

## Step 8: Mark Device as Done

In the impact file (`ESPHOME_<version>.md`), update the **Devices to Reflash** table:
- Change priority to `Done` once reflashed and verified

---

## Directory Structure

```
upgrade/
├── SOP_upgrade.md          ← this file
├── COMPONENTS.md           ← repo component inventory (updated each cycle)
├── ESPHOME_2026.4.5.md     ← impact file for 2026.4.5 (covers 2026.2 → 2026.4.5)
└── ESPHOME_<next>.md       ← created on next upgrade
```

---

## Notes

- Keep only the last 2–3 version impact files; older ones can be archived or deleted.
- `COMPONENTS.md` is a living document — update it whenever a new component is added to any device config.
- The `check_esphome_version.sh` script can be run on cron or at shell startup to get notified of new versions.
