# Repo Structure — Operational Reference

This file is the operational map of `~/dev/esphome_scripts/` for AI agents (FLUX, ECHO) and human maintainers. For each file and directory it states **purpose**, the **update trigger** (when content must change), and whether the entry is an **ECHO satellite** (i.e. ECHO must cross-check it when related changes happen).

See `AGENTS.md` for cross-tool agent definitions, `COMMUNICATION.md` for Larry ↔ agent protocol, and `.claude/agents/echo.md` for ECHO's full heuristic checklist.

## Root-level files

| File | Purpose | Update trigger | ECHO satellite? |
|---|---|---|---|
| `README.md` | Human-facing intro: overview, naming convention, usage, sensor/board catalog | When conventions or device list changes materially | No |
| `AGENTS.md` | Cross-tool AI agent definitions (FLUX + ECHO). Readable by CC, Cursor, Aider, Copilot | When agent behavior or device alias table changes | Yes — update when device renamed/added |
| `CLAUDE.md` | Claude Code entry-point that pulls in `AGENTS.md` and adds CC-specific notes (subagent registration, ECHO trigger pointer) | When CC-specific behavior changes | No |
| `COMMUNICATION.md` | Larry (PKA orchestrator) ↔ repo-local agent protocol — channel, naming, response format, self-contained-task-brief rule | When the orchestration protocol changes | No |
| `STRUCTURE.md` | This file — operational map of the repo for agents | When a top-level file or directory is added, removed, or repurposed | No |
| `Inventory.md` | Hardware stock tracker: boards, sensors, displays by component type + quantity. Decremented when new device created; incremented when components purchased. No file refs or per-device entries. | When device created (decrement) or components purchased (increment) | Yes — see H1/H5 in ECHO profile |
| `BACKLOG.md` | Repo-internal cleanup/audit backlog with severity (Cosmetic/Minor/Notable/Important) and effort (S/M/L). Append-only completion markers `**Status:** ✅ done YYYY-MM-DD`. Not driven by Larry. | When new audit item added or item completed | No |
| `LICENSE` | Repo license (MIT) | Never (legal) | No |
| `esp_upgrade.sh` | Active PROD upgrade workflow — OTA flash commands per device. Used in day-to-day upgrades | When device renamed, added, deleted, or alias flags change | Yes — always paired with `.dir_aliases` |
| `esp_setup.sh` | Fresh-start runbook — used when nothing is flashed/installed and starting from scratch. Active doc, not historical | When device renamed, added, deleted | Yes — always paired with `esp_upgrade.sh` |
| `.dir_aliases` | Zsh directory-scoped aliases loaded automatically on entry. Each alias = flash command for one device | When device renamed, added, deleted, or command format changes | Yes — primary satellite trigger |
| `check_esphome_version.sh` | Checks for new ESPHome version, prompts before upgrade. Used in monthly upgrade cycle | When version check mechanism or source URL changes | No |
| `install_fonts.sh` | Downloads TTF font files listed in `fonts/requirements.txt`. Run after clone or when new font added | When font list changes | No |
| `pt02_rs485_setup.sh` | One-off setup script for Air Quality Monitor PT02 via RS485. Device-specific, not general workflow | Only if PT02 hardware changes | No |
| `re_codes_captured.csv` | IR remote control codes captured via ESP receiver (NEC protocol). Supplemented when new remote captured | When new IR remote codes captured | No |
| `requirements.txt` | Python/ESPHome package dependencies | When ESPHome version pinned or new dependency added | No |
| `secrets.yaml` | Actual credentials — gitignored, not in repo | N/A | No |
| `secrets_example.yaml` | Credential template with placeholder values for new installs | When new secret key added to `secrets.yaml` | No |
| `.pre-commit-config.yaml` | Pre-commit hook definitions (yamllint, gitleaks, ESPHome override-by-order guard, include reference resolver) | When hooks added/updated | No |
| `.yamllint` | YAML linting rules (line-length disabled, key-duplicates disabled) | When lint rules consciously changed | No |
| `.gitignore` | Git ignore rules | When new artifact types or directories added | No |
| `.antigravityignore` | Ignore rules for Antigravity IDE (similar to .gitignore for that tool) | When new directories should be hidden from Antigravity | No |
| `agents_inbox/` | Larry → agent task briefs and agent → Larry responses. Gitignored — runtime channel, not repo content | N/A | No |

## Directories

| Directory | Purpose | Update trigger | ECHO satellite? |
|---|---|---|---|
| `2_PROD/` | Deployed device configs — production. Primary working directory for FLUX | When device flashed to production | Yes — changes here trigger H1 |
| `0_DEV/` | Development/experiment configs. Shares includes with PROD — indirect impact when includes change | When include files change (indirect) | Indirect |
| `1_UAT/` | Pre-production validation configs. Also shares includes — indirect impact | When include files change (indirect) | Indirect |
| `includes/` | Shared YAML blocks: wifi, mqtt, OTA, API, board base configs. Changing one file may affect all 3 environments | When shared behavior changes | Potentially wide impact — flag scope manually |
| `sensors/` | Reusable sensor YAML blocks per chip type, loaded via `!include` | When sensor behavior/params change | No direct satellite, but wide device impact |
| `lights/` | Light component YAML blocks, loaded via `!include` | When light behavior changes | No direct satellite |
| `outputs/` | Output component YAML blocks | When output behavior changes | No direct satellite |
| `switches/` | Switch component YAML blocks | When switch behavior changes | No direct satellite |
| `covers/` | Cover component YAML blocks | When cover behavior changes | No direct satellite |
| `fans/` | Fan component YAML blocks | When fan behavior changes | No direct satellite |
| `buttons/` | Button YAML blocks (also `set_of_*` files for IR remotes, included via `packages:`) | When button/remote behavior changes | No direct satellite |
| `selects/` | Select component YAML blocks | When select behavior changes | No direct satellite |
| `scripts/` | ESPHome automation scripts as YAML, loaded via `!include`. Treat same as other include dirs | When automation behavior changes | No direct satellite |
| `interfaces/` | Interface YAML blocks (i2c, uart, dallas, display pages), loaded via `!include`. Treat same as includes | When interface config changes | No direct satellite |
| `i2s/` | I2S sound device configs (mic, speaker), loaded via `!include` | When I2S behavior changes | No direct satellite |
| `fonts/` | Mixed: TTF font files (downloaded by `install_fonts.sh`) + YAML font config files loaded via `!include` | When new font added or font config changes | No direct satellite |
| `pinouts/` | Pinout images, wiring schematics, connection diagrams, and board photos — reference material for hardware assembly and troubleshooting. Referenced by `Inventory.md` and used when wiring new devices | When new board/component added or wired up | No |
| `docs/` | Component and feature documentation — describes components Pawelo submits PRs for. Reference knowledge for understanding what's available | When writing or updating a PR | No |
| `examples/` | Working YAML examples not used in PROD and not deprecated. Reference scripts | When example patterns are updated | No |
| `custom_components/` | Local modifications to ESPHome components without upstream PRs. Experimental — not in PROD. No satellites | When local experiment changes | No |
| `tests/` | Active test configs for Pawelo's own PRs submitted to ESPHome repo. Must be kept current | When PR behavior changes | No direct satellite, but must stay in sync with PR |
| `tools/` | Python helper scripts used by pre-commit hooks (`check_includes.py`, `check_merge_syntax.py`, `check_yaml_shape.py`, `yamllint_fix.py`) | When a hook's logic or scope changes | No |
| `upgrade/` | Documentation of ESPHome upgrade cycles: per-release notes, SOPs (PR refresh, upgrade flow), component refs | When a new ESPHome release is processed or an SOP is revised | No |
| `esphome-overrides/` | Local override of the upstream ESPHome Python package (used to apply pending PRs / local patches before they land upstream) + `refresh.sh` to re-sync | When the upstream patch surface changes or after refresh | No |
| `deprecated/` | Retired configs that no longer work or are superseded. Archive only — these configs are not functional and are kept for historical reference | Never (archive) | No |
| `temp/` | Temporary working files. Gitignored | N/A | No |
| `.claude/` | Claude Code agent profiles (FLUX, ECHO) under `.claude/agents/`, plus optional CC settings | When agent profiles change | No |

## Notes for agents

- The **ECHO satellite** column is the canonical input for ECHO's heuristic checklist (`.claude/agents/echo.md`, H1–H6). When ECHO needs to know "what else might need updating when X changes," start here.
- `agents_inbox/` (gitignored) and `BACKLOG.md` (committed) are **two independent work streams**. Do not conflate them.
- `secrets.yaml` is gitignored. Always reference secrets via `!secret <name>`; the template in `secrets_example.yaml` is the source of truth for what keys must exist.
