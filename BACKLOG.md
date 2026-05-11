---
tags:
  - review
  - area/esphome
  - area/homelab
created: 2026-05-10
updated: 2026-05-10
status: active
author: DEX
type: research
review_by: 2026-11-10
brief: team_inbox/dex_esphome_strange_patterns.md
prior_deliverable: inbox/dex_esphome_repo_review.md
---

# ESPHome Strange Patterns — Exhaustive Inventory

Flat enumeration of every strange / non-idiomatic / inconsistent / outdated pattern found in `~/dev/esphome_scripts/`. Read-only inventory — no files modified. Each entry is small enough to convert to a KANBAN card.

Scope walked: `2_PROD/*.yaml` (all 11), representative `0_DEV/*.yaml`, `includes/*.yaml`, `interfaces/*.yaml`, `sensors/*.yaml`, `buttons/*.yaml`, `covers/*.yaml`, `outputs/*.yaml`, `lights/*.yaml`, `switches/*.yaml`, `i2s/*.yaml`, `secrets.yaml`, `secrets_example.yaml`, `.yamllint`, `.pre-commit-config.yaml`, `.gitignore`, `upgrade/SOP_upgrade.md`, `README.md`, `AGENTS.md`. `1_UAT/` has only `.gitignore` (no active files).

## Table of contents

- [A. Filename casing & case-mismatch references](#a-filename-casing--case-mismatch-references) — items 1–4
- [B. Real bugs (parse/runtime risk)](#b-real-bugs-parserruntime-risk) — items 5–7
- [C. esphome_min_version drift & central source](#c-esphome_min_version-drift--central-source) — items 8–11 (CLIO minor 5–6)
- [D. Override-by-order / packages migration debt](#d-override-by-order--packages-migration-debt) — items 12–17
- [E. Per-device boilerplate duplication](#e-per-device-boilerplate-duplication) — items 18–23
- [F. Substitution misuse / version drift / metadata](#f-substitution-misuse--version-drift--metadata) — items 24–32
- [G. Wifi / network include hygiene](#g-wifi--network-include-hygiene) — items 33–37
- [H. MQTT / api / logger include hygiene](#h-mqtt--api--logger-include-hygiene) — items 38–43
- [I. Board file inheritance & edge cases](#i-board-file-inheritance--edge-cases) — items 44–49 (CLIO blind spot 3 = item 47)
- [J. GPIO / hardware opacity](#j-gpio--hardware-opacity) — items 50–53
- [K. Dead / commented-out code](#k-dead--commented-out-code) — items 54–60
- [L. Naming convention violations](#l-naming-convention-violations) — items 61–64
- [M. Pre-commit / lint coverage gaps](#m-pre-commit--lint-coverage-gaps) — items 65–71 (CLIO blind spot 1 = items 65, 70; CLIO minor 4 = item 69)
- [N. Secrets handling](#n-secrets-handling) — items 72–76 (CLIO blind spot 2)
- [O. Documentation drift](#o-documentation-drift) — items 77–81
- [P. Misc / cosmetic](#p-misc--cosmetic) — items 82–86

[Summary table](#summary-table) at the bottom.

---

## A. Filename casing & case-mismatch references

### 1. Mixed casing in `sensors/` filenames vs lowercase elsewhere

**Where:** `sensors/binary_HA_connected.yaml`, `sensors/HA_sensor.yaml`, `sensors/binary_from_HA_sensor.yaml`, `sensors/temp_hum_SHT3x.yaml`, `sensors/temp_hum_SHT4x.yaml`, `sensors/temp_hum_AHT2x.yaml`, `sensors/current_power_voltage_INA226.yaml`, `sensors/current_power_voltage_INA3221.yaml`, `sensors/text_IAQ_accuracy_bme68x.yaml`, `sensors/percentage_battery_lilygo_T5_47.yaml`, `sensors/voltage_battery_lilygo_T5_47.yaml`, `sensors/text_powered_from_lilygo_T5_47.yaml`, `sensors/water_YF-B10.yaml`, `sensors/water_flow_diff_YF-B10.yaml`, `sensors/water_total_diff_YF-B10.yaml`, `sensors/water_used_YF-B10.yaml`, `sensors/water_used_diff_YF-B10.yaml`
**What:** ~17 sensor files use uppercase parts (HA, SHT, AHT, INA, IAQ, T5, YF) while ~63 sibling files use lowercase. AGENTS.md says "Include files: `category_specific_name.yaml`" with no exception for vendor IDs.
**Why fix:** Consistency. Mixed case on a case-insensitive macOS filesystem hides bugs (item 2). Sibling files in `sensors/` already exist in lowercase form for similar vendor IDs (`lux_bh1750.yaml`, `lux_tcs3472.yaml`, `temp_ds18b20.yaml`, `temp_hum_co2_scd40.yaml`, `temp_hum_press_bme280.yaml`, `temp_hum_press_gas_bme680.yaml`, `tvoc_eco2_sgp30.yaml`, `tvoc_eco2_ens160.yaml`).
**Suggested fix:** Pick a convention (recommend lowercase everywhere per AGENTS.md), `git mv` rename in two commits (lowercase → temp uppercase → final lowercase, to survive case-insensitive FS), and grep-replace references in PROD/DEV.
**Effort:** L
**Severity:** Notable
**Status:** ✅ done 2026-05-10

### 2. ~139 case-mismatch `!include` references between PROD/DEV files and the on-disk sensor filenames

**Where:** `2_PROD/*.yaml` lines referencing `binary_ha_connected.yaml` (lowercase, but git-tracked is `binary_HA_connected.yaml`), `lux_BH1750.yaml` (uppercase, but git-tracked is `lux_bh1750.yaml`), `temp_hum_co2_SCD40.yaml` (uppercase, but git-tracked is `temp_hum_co2_scd40.yaml`), `temp_DS18B20.yaml` (uppercase, but git-tracked is `temp_ds18b20.yaml`), `temp_hum_press_BME280.yaml` (uppercase, but git-tracked is `temp_hum_press_bme280.yaml`), `tvoc_eco2_SGP30.yaml` (uppercase, but git-tracked is `tvoc_eco2_sgp30.yaml`), `lux_TCS3472.yaml` (uppercase, but git-tracked is `lux_tcs3472.yaml`), `text_air_quality_bme68x_bsec2.yaml` (referenced but does not exist), etc. Concrete examples: `2_PROD/esp12f-10_Office.yaml:95,114,118,122`, `2_PROD/esp12f-21_Underfloor.yaml:118-119,125`, `2_PROD/esp32-14_Salon.yaml:172,194,198`, `2_PROD/esp32-35_Pump_Garage.yaml:181,218,222,226`. Total occurrences across PROD+DEV: ~139.
**What:** YAML `!include` references use a case that doesn't match the actual git-tracked filename. macOS HFS+/APFS is case-insensitive by default, so the configs compile and flash; on a case-sensitive Linux runner (CI, GitHub Actions, ESPHome dashboard add-on, Docker) the same configs would fail with `FileNotFoundError`.
**Why fix:** Safety. Compiles only on Pawelo's macOS — any future migration to Linux/CI/dashboard breaks every PROD file. Hidden landmine.
**Suggested fix:** After item 1 settles a single case convention, sweep all `!include` lines and rewrite to match. Add a pre-commit hook that resolves each `!include`'d path and fails if it doesn't match the on-disk case (see item 65).
**Effort:** L
**Severity:** Important
**Status:** ✅ done 2026-05-10

### 3. Reference to non-existent file `sensors/text_air_quality_bme68x_bsec2.yaml`

**Where:** `2_PROD/esp12f-11_Entrance_Entry.yaml:97-98`, both lines commented out: `# - !include ../sensors/text_air_quality_bme68x_bsec2.yaml #!not working (bricked ESP12F device)` and `# - !include ../sensors/text_IAQ_accuracy_bme68x_bsec2.yaml`. Closest file on disk: `text_air_quality_bme68x.yaml` and `text_IAQ_accuracy_bme68x.yaml` (no `_bsec2` suffix).
**What:** Comment refers to file that never existed in the repo. If un-commented after a future fix, would error.
**Suggested fix:** Either rename current `text_air_quality_bme68x.yaml` → `text_air_quality_bme68x_bsec2.yaml` (matches `i2c_bme68x_bsec2.yaml` interface naming), or fix the comment to reference the actual file.
**Effort:** S
**Severity:** Cosmetic

### 4. `.yml` extension used in three 0_DEV files instead of `.yaml`

**Where:** `0_DEV/esp32-33_s3_VA.yml`, `0_DEV/esp32_display_ttgo.yml`, `0_DEV/miniss_dev.yml`. Every other config file in the repo uses `.yaml`.
**What:** Inconsistent extension. The pre-commit `check-yaml` hook still picks them up (it globs both `.yaml` and `.yml`), but `yamllint` in `.pre-commit-config.yaml` does not — yamllint defaults to checking only the file types its config matches.
**Suggested fix:** `git mv esp32-33_s3_VA.yml esp32-33_s3_VA.yaml` etc.
**Effort:** S
**Severity:** Cosmetic
**Status:** ❌ cancelled 2026-05-11 — **wontfix**: `.yml` is a deliberate marker for scripts that don't currently compile (excluded from the `find *.yaml` upgrade sweep in `esp_upgrade.sh`). Convention now documented in AGENTS.md § File Naming Conventions.

---

## B. Real bugs (parser/runtime risk)

### 5. Malformed quote in `wire_id` value

**Where:** `2_PROD/esp12f-21_Underfloor.yaml:122` — `#  - !include { file: ../sensors/temp_DS18B20.yaml, vars: { ix: "Dlong", wire_id: "ow_a, address: "0x0b0417c42dceff28", min_temp: -10, max_temp: 50 } } # 2m cable`
**What:** Closing quote on `wire_id` is missing — `"ow_a, address:` instead of `"ow_a", address:`. Currently harmless because the line is commented out; if uncommented it would parse as `wire_id = ow_a, address: 0x...` which YAML would either reject or interpret unexpectedly.
**Why fix:** Trap waiting to be sprung. The intent is clearly to enable the `Dlong` sensor by uncommenting.
**Suggested fix:** Add the missing quote: `wire_id: "ow_a", address: "0x0b0417c42dceff28"`.
**Effort:** S
**Severity:** Notable
**Status:** ✅ done 2026-05-11

### 6. Typo `wifi__bssod.yaml` in secrets.yaml comment

**Where:** `secrets.yaml:13` — `wifi__bssid: "..." # BSSID of the access point to avoid connecting to wrong network with same SSID (use wifi__bssod.yaml)`. Compare with `secrets_example.yaml:14` which has it correct: `(use wifi__bssid.yaml)`.
**What:** Typo `bssod` instead of `bssid` in pointer comment. Only confusing on read.
**Suggested fix:** Replace `bssod` with `bssid`.
**Effort:** S
**Severity:** Cosmetic
**Status:** ✅ done 2026-05-11 (note: `secrets.yaml` is gitignored — fix applied locally only)

### 7. `globals_water_totals_restore.yaml` defines variables that diverge from the loaded `board_esp32__water_pump.yaml`

**Where:** `includes/globals_water_totals_restore.yaml:6-13` defines `global_water_total_all` and `global_water_total_garden` (with underscore between `water` and `total`). `includes/board_esp32__water_pump.yaml:23,27` (which is what esp32-35 actually loads) defines `global_watertotal_all` and `global_watertotal_garden` (no underscore). `2_PROD/esp32-35_Pump_Garage.yaml:121` loads `board_esp32__water_pump.yaml`, not `globals_water_totals_restore.yaml`.
**What:** Two competing definitions for "the same thing" — different variable names. Whichever one is loaded wins. Right now esp32-35 loads the no-underscore version via the board file. The other file is unreachable orphan code.
**Why fix:** A future "let me move globals out of the board file" refactor will hit a name mismatch. Confuses readers about which is canonical.
**Suggested fix:** Decide one canonical name (recommend `global_water_total_*` for readability), update both files + the lambdas in `board_esp32__water_pump.yaml:64-77` and `api_services__water.yaml:33-46`. Or delete `globals_water_totals_restore.yaml` if it's not used.
**Effort:** M
**Severity:** Notable

---

## C. esphome_min_version drift & central source

### 8. `esphome_min_version` declared on only 3 of 11 PROD files (CLIO minor 6: actual grep audit)

**Where:** Confirmed via `grep -rn 'esphome_min_version' 2_PROD/`:
- `2_PROD/esp32-06_Garden_Gateway.yaml:23` → `2025.6.3`
- `2_PROD/esp32-14_Salon.yaml:50` → `2025.8.0`
- `2_PROD/esp32-35_Pump_Garage.yaml:68` → `2025.6.3`

8 PROD files have **no** `esphome_min_version` declaration: `esp12f-10_Office.yaml`, `esp12f-11_Entrance_Entry.yaml`, `esp12f-15_Upstairs.yaml`, `esp12f-21_Underfloor.yaml`, `esp12f-25_AquariumWindow.yaml`, `esp32-05_Shades_WinterGardenUpp.yaml`, `esp32-36_Garage_Gate.yaml`, `esp32-39_Attic.yaml`. (The prior audit said only 06 and 14 had it — actually 35 also has it. Audit corrected.)
**What:** Pinning protects against silent reinterpretation by an older ESPHome installation.
**Suggested fix:** Add one substitution line to each of the 8 PROD files at the same default level as the existing 3 (currently `2025.6.3`).
**Effort:** M
**Severity:** Notable
**Status:** ✅ done 2026-05-10 (covered alongside items 9+10 in commit `69b28f9` — per-device floor pins added to all 11 PROD files)

### 9. `esphome_min_version` only takes effect when `min_version: ${esphome_min_version}` is wired in the board file — and only `board_esp32_with_psram_fix.yaml` wires it

**Where:** `includes/board_esp32_with_psram_fix.yaml:26` → `min_version: ${esphome_min_version}` is the only `min_version:` line in any board include. The other board files (`board_esp32.yaml`, `board_esp8266.yaml`, `board_esp32__esp-idf.yaml`, `board_esp32__water_pump.yaml`, `board_esp32_variant.yaml`, `board_miniss_bk7231n.yaml`) do **not** read the substitution.
**What:** So even though `esp32-06_Garden_Gateway.yaml:23` sets `esphome_min_version: 2025.6.3`, the value is never consumed because `board_esp32.yaml` doesn't reference `${esphome_min_version}`. Same for esp32-35 (uses `board_esp32__water_pump.yaml`). Only esp32-14 (using `board_esp32_with_psram_fix.yaml`) actually enforces the pin.
**Why fix:** This is a silent failure mode — the substitution is set but does nothing. Pawelo thinks the pin is enforced, but for 06 and 35 it isn't.
**Suggested fix:** Add `min_version: ${esphome_min_version}` to the `esphome:` block of every board include file. Combined with item 10 (default value), this makes the pin uniform.
**Effort:** S
**Severity:** Important
**Status:** ✅ done 2026-05-10

### 10. No central default for `esphome_min_version` substitution (CLIO minor 5)

**Where:** Each PROD file would need to declare `esphome_min_version` independently (currently 3 of 11 do). No `defaults:` mechanism.
**What:** Per CLIO blind spot — central source would be a single substitution rather than 11 hand-typed strings. Without a default, devices that don't declare the substitution and load a board file that wires `min_version: ${esphome_min_version}` would fail YAML resolution.
**Suggested fix:** Two paths:
- (a) Add a per-file substitution to all 11 PROD files (mechanical, ~5 min/file).
- (b) Add a default substitution at the top of each board include file via the `vars:` defaults pattern in ESPHome `!include {file:..., vars:{...}}`. This requires every device to call the board file with explicit `vars: {esphome_min_version: ${esphome_min_version}}` or a default in the board file.
- (c) Most idiomatic: use `packages:` and let it surface a single shared default.

Recommend (a) for consistency with current style + add to upgrade SOP a check that the value matches the currently-installed version (`upgrade/COMPONENTS.md` already tracks this).
**Effort:** M
**Severity:** Notable
**Status:** ✅ done 2026-05-10

### 11. `esphome_max_version` substitution declared but never enforced

**Where:** `2_PROD/esp32-35_Pump_Garage.yaml:69` → `esphome_max_version: 2026.2 #! last version where FRAM component works`
**What:** Substitution defined as a comment-anchor, but no ESPHome mechanism reads `esphome_max_version`. ESPHome only supports `min_version`. The substitution exists purely as documentation.
**Why fix:** Misleading — looks like a guard but is inert. If ESPHome ever ships breaking FRAM changes, the device flashes silently.
**Suggested fix:** Either remove the substitution and put the constraint in a comment (`#! Do not upgrade beyond 2026.2 — FRAM component breaks`), or build the check into the upgrade SOP grep (item 65 / 70).
**Effort:** S
**Severity:** Minor

---

## D. Override-by-order / packages migration debt

(See prior audit `inbox/dex_esphome_repo_review.md` § Override-by-Order Analysis for context. Items below are the concrete pending migrations / clean-ups.)

### 12. Override-by-order (`<<: !include`) used for board base in 11 PROD files

**Where:** Every PROD file uses `<<: !include { file: ../includes/board_esp8266.yaml, vars: {} }` or `board_esp32.yaml` etc. Could be in `packages:` (already done in `2_PROD/esp32-06_Garden_Gateway.yaml:75-77` and `2_PROD/esp32-14_Salon.yaml:124-148` for non-board includes).
**What:** Pre-`packages:` pattern. Functionally correct (per `yaml_util.py` first-key-wins), but stylistic gap vs the modern alternative.
**Why fix:** Long-term maintainability. New ESPHome users / AI agents reading the configs won't expect `<<: !include` pattern.
**Suggested fix:** Audit-recommended P2-4 — touch every PROD file in one mechanical sweep, plus remove `<<: !include wifi.yaml` etc. from board files. Big change but mechanical. Defer until a maintenance pass already touches every PROD file.
**Effort:** L
**Severity:** Minor (cross-ref to prior audit P2-4)

### 13. Override-by-order used for `time_sntp_with_sun.yaml` in 6 PROD files

**Where:** `2_PROD/esp32-06_Garden_Gateway.yaml:48`, `2_PROD/esp32-14_Salon.yaml:76`, `2_PROD/esp32-35_Pump_Garage.yaml:109`, `2_PROD/esp32-39_Attic.yaml:69`, `2_PROD/esp32-05_Shades_WinterGardenUpp.yaml:94`, `2_PROD/esp32-36_Garage_Gate.yaml:54` — each uses top-level `<<: !include ../includes/time_sntp_with_sun.yaml` to override the default `time_sntp.yaml` from board file.
**What:** First-key-wins makes this work. Stylistic.
**Suggested fix:** Promote to `packages: { time: !include ../includes/time_sntp_with_sun.yaml }` and remove `<<: !include time_sntp.yaml` from board files. Or consolidate to one `time.yaml` driven by a substitution `${time_extras: empty|sun}` (similar to mqtt_with_rtttl).
**Effort:** M
**Severity:** Minor

### 14. Override-by-order used for `mqtt_with_rtttl.yaml` in 7 PROD files

**Where:** `2_PROD/esp12f-10_Office.yaml:62`, `esp12f-11_Entrance_Entry.yaml:68`, `esp12f-21_Underfloor.yaml:65`, `esp12f-25_AquariumWindow.yaml:61`, `esp32-06_Garden_Gateway.yaml:49`, `esp32-14_Salon.yaml:77`, `esp32-35_Pump_Garage.yaml:110`. All override the default `mqtt.yaml` from board file.
**What:** Two near-identical mqtt files (`mqtt.yaml` vs `mqtt_with_rtttl.yaml`) differ only in `keepalive` and `on_message:` — half of every PROD device overrides one with the other. Cross-ref to prior audit P2-3.
**Suggested fix:** Single `mqtt.yaml` driven by substitution `${mqtt_extras: empty|rtttl}` would remove this whole override chain and leave only one mqtt include.
**Effort:** M
**Severity:** Minor

### 15. Override-by-order used for `logger_level.yaml` in 2 PROD files

**Where:** `2_PROD/esp32-14_Salon.yaml:78`, `2_PROD/esp32-36_Garage_Gate.yaml:56` — `<<: !include { file: ../includes/logger_level.yaml, vars: { level: INFO, baud_rate: 115200 } }`. Other 9 PROD files have it commented out.
**What:** When uncommented, this overrides the default `logger.yaml` from the board file. The two existing logger files (`logger.yaml` vs `logger_level.yaml`) differ only in: (a) hardcoded vs variable level, (b) hardcoded vs variable baud_rate, (c) one extra line in logger_level for `mqtt: INFO` etc.
**Suggested fix:** Replace `logger.yaml` with `logger_level.yaml` everywhere (give it sensible defaults `level=INFO, baud_rate=0`), delete `logger.yaml`. Saves one override site.
**Effort:** M
**Severity:** Minor

### 16. Override-by-order used for `api_services.yaml` and `api_services__water.yaml` in 3 PROD files

**Where:** `2_PROD/esp32-06_Garden_Gateway.yaml:57`, `2_PROD/esp32-36_Garage_Gate.yaml:63` (api_services), `2_PROD/esp32-35_Pump_Garage.yaml:118` (api_services__water).
**What:** `api_services.yaml` overrides the plain `api.yaml` default. Same first-key-wins mechanism as wifi/mqtt. The `api.yaml` from the board chain is silently skipped.
**Suggested fix:** Either move to `packages:`, or merge `api.yaml` and `api_services.yaml` into one `api.yaml` driven by substitution `${api_services: empty|generic|water}`.
**Effort:** M
**Severity:** Minor

### 17. Override-by-order used for `qr_guestwifi.yaml` and `globals_display_cycle.yaml` in 2 PROD files

**Where:** `2_PROD/esp32-05_Shades_WinterGardenUpp.yaml:109,111`, `2_PROD/esp32-35_Pump_Garage.yaml:124`. Both use `<<: !include qr_guestwifi.yaml` and `<<: !include { file: ../includes/globals_display_cycle.yaml, vars: { restore: false } }` at the top level of the device file.
**What:** These are not really "overrides" — they're injecting net-new content (qr_code, globals) at top level. The merge-key syntax works but is the wrong tool. The right tool is `packages:`.
**Suggested fix:** Move to `packages:` block. Cleaner reading and explicit intent ("I'm adding a package, not overriding a key").
**Effort:** S
**Severity:** Minor

---

## E. Per-device boilerplate duplication

### 18. Substitutions block boilerplate copy-pasted across 11 PROD files

**Where:** Every PROD file has a near-identical `substitutions:` block of ~20 lines with the same fields (`devicename: esp32-xx`, `updates: "30s"`, `room: Room`, `mqtt_location: home`, `mqtt_room: room`, `accuracy_decimals: "2"`, `project_name: "pgolawsk.esp_home"`, `flash_write_interval: "5min"`, etc.). Concrete: compare `2_PROD/esp12f-10_Office.yaml:38-58` with `2_PROD/esp12f-21_Underfloor.yaml:41-61` — 18 of 20 lines match.
**What:** ~200 lines of repeated config with default values that are usually overridden via CLI `-s`.
**Why fix:** Adding a new substitution requires touching all 11 files.
**Suggested fix:** Extract a `substitutions_defaults.yaml` package, include via `packages:`. Each device file keeps only the fields it customizes (mostly `devices:`, `version:`, `board:`, `flash_size:`).
**Effort:** L
**Severity:** Minor

### 19. The "override block of commented-out alternative wifi files" boilerplate is in 11 PROD files

**Where:** Every PROD file has lines like:
```yaml
# <<: !include ../includes/wifi_outside.yaml
# <<: !include { file: ../includes/wifi_main.yaml, vars: { } }
# <<: !include { file: ../includes/wifi_extended.yaml, vars: { } }
# <<: !include { file: ../includes/wifi_extended2.yaml, vars: { } }
```
4–5 commented options for switching wifi network. Same on every device.
**What:** Documentation-as-comments scattered across 11 places. If a wifi file is added/renamed/deleted, all 11 device files must be updated.
**Suggested fix:** Move the menu of wifi options into a docstring at the top of `includes/wifi.yaml` (or AGENTS.md). In each device file, keep only the line that's currently active.
**Effort:** M
**Severity:** Cosmetic
**Status:** ✅ done 2026-05-11 (variant A3: docstring header added to `includes/wifi.yaml` listing all 6 variants + override-by-order instructions; wifi-variant boilerplate replaced with single-line pointer comment in 11 PROD + 23 0_DEV files; orphan `wifi_extended`/`wifi_multi` comments removed from `board_esp32__water_pump.yaml`. Audit confirmed all 11 PROD use default `wifi.yaml` via board files — no active overrides.)

### 20. `restart_button.yaml` + `safe_mode_restart_button.yaml` + `factory_reset_button.yaml` triplet repeated in every PROD file

**Where:** 11 PROD files each have:
```yaml
- !include { file: ../buttons/restart_button.yaml }
- !include { file: ../buttons/safe_mode_restart_button.yaml }
- !include { file: ../buttons/factory_reset_button.yaml }
```
Plus `# - !include { file: ../buttons/shutdown_button.yaml }` (commented).
**What:** Could be a single `set_diagnostic_buttons.yaml` package that pulls in all three.
**Suggested fix:** Create `buttons/set_diagnostic_buttons.yaml` with the triplet; include via `packages: { diagnostic: !include ../buttons/set_diagnostic_buttons.yaml }`.
**Effort:** M
**Severity:** Cosmetic

### 21. `text_uptime` + `text_version` + `text_wifi_info` + `text_debug` repeated in every PROD file

**Where:** 11 PROD files. Same as item 20 but for `text_sensor:` block.
**Suggested fix:** Same — `set_diagnostic_text_sensors.yaml` package.
**Effort:** M
**Severity:** Cosmetic

### 22. `wifi_signal` + `wifi_strength` + `uptime` + `debug` repeated in every PROD file

**Where:** Same pattern, `sensor:` block.
**Suggested fix:** Same — `set_diagnostic_sensors.yaml` package.
**Effort:** M
**Severity:** Cosmetic

### 23. `value_mqtt_subscribe.yaml` block of 9 sensors duplicated across `esp32-05` and `esp32-35`

**Where:** `2_PROD/esp32-05_Shades_WinterGardenUpp.yaml:179-190` and `2_PROD/esp32-35_Pump_Garage.yaml:244-255` — both subscribe to the same set of MQTT topics for displaying neighboring sensors on their ePaper. 22 lines copy-pasted.
**Suggested fix:** Extract `set_subscribed_neighbor_sensors.yaml` package.
**Effort:** S
**Severity:** Cosmetic

---

## F. Substitution misuse / version drift / metadata

### 24. `accuracy_decimals: "2"` substitution declared in every PROD file but never read

**Where:** Every PROD file has `accuracy_decimals: "2"` in substitutions (e.g. `esp12f-10_Office.yaml:58`, `esp32-14_Salon.yaml:71`). Grepping `${accuracy_decimals}` across the repo shows it's used **only** in `sensors/HA_sensor.yaml:12` — and that file is included only by `esp32-35_Pump_Garage.yaml`. Other 10 PROD devices declare the substitution but never consume it.
**What:** Dead substitution in 10 of 11 files.
**Suggested fix:** Either start using it in sensor configs (so `BME280` etc. respect it via `accuracy_decimals: ${accuracy_decimals}`), or remove it from PROD substitution blocks where unused.
**Effort:** S
**Severity:** Minor

### 25. `room2`/`mqtt_location2`/`mqtt_room2` declared in 4 PROD files; `none` literal used as sentinel

**Where:** `2_PROD/esp12f-11_Entrance_Entry.yaml:57-59`, `esp32-39_Attic.yaml:61-63`, `esp32-35_Pump_Garage.yaml:90-92`, `esp32-05_Shades_WinterGardenUpp.yaml:79-81` — `room2: none`, `mqtt_location2: none`, `mqtt_room2: none`.
**What:** When the device doesn't have a secondary room, the substitution is set to literal string `"none"`. Then sensor includes pass `room: "${room2}"` which produces an MQTT topic like `home/none/temperature` or a friendly name `"none Temperature"`. It works but is ugly.
**Suggested fix:** Either set `room2: ""` (empty string acts as no-op for topic concatenation, but produces odd entity names too), or guard the substitution at use site (`{% if room2 != 'none' %}`-style — but ESPHome substitutions don't support conditionals). Or just don't declare `room2` if not needed and don't include the per-room sensors.
**Effort:** S
**Status:** ✅ done 2026-05-11 (variant B: `none` sentinel replaced with real defaults from `.dir_aliases` across 11 PROD + 2 working 0_DEV; added missing `room2/mqtt_location2/mqtt_room2` to esp32-06 (fix undefined-sub crash) and esp32-36; removed unused `room2` triple from esp32-39; aliases slimmed to `esphome run <yaml> --device <host>.lan`. `esphome config` validates clean for esp10/esp32-05/esp32-06/esp32-39 without CLI overrides.)
**Severity:** Minor

### 26. `version: "YYYYMMDD"` substitution drifts behind the actual last edit

**Where:** All PROD files declare `version:` as a date string. Most recent ones in audit:
- `esp12f-10_Office.yaml:41` → `"20251218"` (last edit 2025-11-30 per changelog — already drifted by 18 days)
- `esp12f-11_Entrance_Entry.yaml:41` → `"20251223"` (last edit 2025-11-23)
- `esp12f-21_Underfloor.yaml:44` → `"20251122"` (last edit 2025-11-22)
- `esp32-14_Salon.yaml:49` → `"20260123"` (last edit 2026-01-23 — but file modified after that per changelog 2026-02-21)
- `esp32-35_Pump_Garage.yaml:67` → `"20251205"` (last edit 2026-01-24)
**What:** Manual version field that nobody remembers to bump. Harmless but misleading.
**Suggested fix:** Either drop the field (the OTA mechanism doesn't need it), or auto-bump via a pre-commit hook that updates `version:` to today's date when the file is staged.
**Effort:** S
**Severity:** Cosmetic

### 27. `restore_mode` substitution declared only on esp32-14, used inconsistently

**Where:** `2_PROD/esp32-14_Salon.yaml:72` → `restore_mode: ALWAYS_OFF`. No other PROD file has it. Only relevant if some include consumes `${restore_mode}`.
**What:** Grepping shows nothing in includes consumes `${restore_mode}`. Looks like an orphaned substitution.
**Suggested fix:** Either remove, or wire it into a switch/light include that reads it.
**Effort:** S
**Severity:** Minor

### 28. `framework_type` and `framework_version` declared per-device — drift between devices

**Where:** `2_PROD/esp32-05` line 62: `framework_type: esp-idf`; `2_PROD/esp32-06` line 27: `framework_type: esp-idf`; `2_PROD/esp32-14` line 54: `framework_type: esp-idf`; `2_PROD/esp32-36` line 32: `framework_type: arduino`; `2_PROD/esp32-39` line 44: `framework_type: esp-idf`; `2_PROD/esp32-35` line 72: `framework_type: arduino`. ESP8266 boards default in `board_esp8266.yaml` but don't expose it as substitution. `framework_version: recommended` everywhere.
**What:** Two ESP32 PROD files run Arduino, three run ESP-IDF. The reasons live in changelog comments scattered across files (e.g., esp32-35: "FRAM works with Arduino with no deprecation warnings"; esp32-36: "switched back to Arduino as ESP-IDF was not activated somehow"). Hard to see at a glance which framework each device runs.
**Suggested fix:** Add a one-line summary table to AGENTS.md or `upgrade/COMPONENTS.md` listing each device + framework + reason.
**Effort:** S
**Severity:** Minor

### 29. `minimum_chip_revision` substitution declared inconsistently — only 4 of 8 ESP32 PROD files have it

**Where:** Has it: `2_PROD/esp32-06_Garden_Gateway.yaml:34`, `esp32-39_Attic.yaml:51`, `esp32-35_Pump_Garage.yaml:80`, `esp32-05_Shades_WinterGardenUpp.yaml:69`. Doesn't have it: `esp32-14_Salon.yaml`, `esp32-36_Garage_Gate.yaml` (commented out at line 40 with "removed minimum_chip_revision variable as this is C3"). And `board_esp32.yaml:57` references `${minimum_chip_revision}` while `board_esp32_with_psram_fix.yaml` does NOT (used by esp32-14 — that's why esp32-14 doesn't need it). And `board_esp32_variant.yaml` (used by esp32-36) explicitly drops it.
**What:** The interlocking of "which board file consumes the substitution" with "which device sets it" is fragile. Reader can't tell from a device file alone whether `minimum_chip_revision` is required.
**Suggested fix:** Add a comment in each board file's substitutions stub block saying which substitutions it expects; add a one-line guard in the device file's substitutions block: `# This file uses board_esp32.yaml — minimum_chip_revision required`.
**Effort:** S
**Severity:** Minor

### 30. `flash_size` substitution declared on every ESP32 device but inconsistently for ESP8266

**Where:** ESP32 devices declare `flash_size: 4MB` or `8MB`. ESP8266 devices declare `restore_from_flash: "false"` and `flash_write_interval: "5min"` but **not** `flash_size`. `board_esp8266.yaml` doesn't reference `${flash_size}`.
**What:** Asymmetry by hardware. Acceptable, but not documented.
**Suggested fix:** Add a comment to ESP8266 PROD files: `# board_esp8266.yaml ignores flash_size — set via PlatformIO board variant`.
**Effort:** S
**Severity:** Cosmetic

### 31. `${platform_name}` and `${web_server_version}` are wired but the variables are interpolated as substitutions, not via `vars:` mechanism

**Where:** `includes/web_server.yaml:13` reads `${ota_enabled}` and line 17 `${web_server_version}` — both consumed via standard `${}` substitution. Same for `psram.yaml`, `logger_level.yaml`, etc.
**What:** Mix of two ESPHome conventions: (a) simple `${name}` substitutions defined at device-file level or via `!include {file:..., vars:{...}}`, (b) board includes that pull from device-level substitutions via top-level `<<: !include` chain. Both work. Not strictly an issue but the "vars vs substitution" distinction is invisible.
**Suggested fix:** Pick one convention or document the rationale in AGENTS.md. (Currently AGENTS.md briefly mentions `vars:` syntax but doesn't say when to use it vs plain substitutions.)
**Effort:** S
**Severity:** Cosmetic

### 32. `restore_value: ${restore}` pattern works only when `${restore}` is a literal `true` or `false`

**Where:** `includes/globals_display_cycle.yaml:11,15,19` and `includes/globals_water_totals_restore.yaml:8,12` — `restore_value: ${restore}`. Devices pass `vars: { restore: false }` (e.g. `esp32-05_Shades_WinterGardenUpp.yaml:111`).
**What:** ESPHome substitutions are string interpolation. Whether `false` substitutes as YAML boolean false or string `"false"` depends on quoting. This works because ESPHome's loader coerces — but is fragile (cf. `restore_from_flash: "false"` comment in board files: "must be set as string to work").
**Suggested fix:** Quote the var explicitly: `restore_value: ${restore}` → `restore_value: "${restore}"` and pass strings; or document the quirk in AGENTS.md.
**Effort:** S
**Severity:** Cosmetic

---

## G. Wifi / network include hygiene

### 33. 7 wifi variant files; 4 are likely stale

**Where:** `includes/wifi.yaml`, `wifi_main.yaml`, `wifi_outside.yaml`, `wifi__bssid.yaml`, `wifi_extended.yaml`, `wifi_extended2.yaml`, `wifi_multi.yaml`.

Audit: grepping for un-commented uses of each across PROD/DEV gives:
- `wifi.yaml` — used as default in every board file
- `wifi_main.yaml` — only commented references in PROD/DEV
- `wifi_outside.yaml` — only commented references in PROD/DEV
- `wifi__bssid.yaml` — only commented references in PROD/DEV (was active on esp32-14 until 2025-12-20 per changelog, then removed)
- `wifi_extended.yaml` — only commented references in PROD/DEV
- `wifi_extended2.yaml` — only commented references in PROD/DEV
- `wifi_multi.yaml` — only one commented reference in `board_esp32__water_pump.yaml:142`

**What:** All non-default wifi files are dormant. The audit recommended P2-2 deprecate-unused — concrete list: `wifi__bssid.yaml`, `wifi_extended.yaml`, `wifi_extended2.yaml`, `wifi_multi.yaml`, possibly `wifi_main.yaml`.
**Suggested fix:** Move stale ones to `deprecated/`. Cross-ref P2-2 in prior audit.
**Effort:** M
**Severity:** Cosmetic

### 34. `wifi_main.yaml` and `wifi.yaml` differ only in: (a) `reboot_timeout`, (b) ssid secret name

**Where:** Compare `includes/wifi.yaml:25` (`reboot_timeout: 45min`) with `includes/wifi_main.yaml:14` (`reboot_timeout: 15min`).
**What:** Same template, two values. Could be one file with `${reboot_timeout}` and `${wifi_secret_prefix}` substitutions.
**Suggested fix:** Single `wifi.yaml` with substitutions for `${ssid_secret_name}`, `${password_secret_name}`, `${reboot_timeout}`.
**Effort:** M
**Severity:** Minor

### 35. `wifi_extended.yaml` and `wifi_extended2.yaml` — copies that comment in/out which `wifiN_*` block is active

**Where:** `includes/wifi_extended.yaml:12-20` and `includes/wifi_extended2.yaml:12-20`. The two files differ only in which network entry is uncommented (wifi2 vs wifi3).
**What:** Anti-pattern. Two files for two trivial choices.
**Suggested fix:** Replace both with `wifi_indexed.yaml` taking `${index}` and using `!secret wifi${index}_ssid` / `!secret wifi${index}_password`. Or just use `wifi_multi.yaml` (already exists, has all 3).
**Effort:** S
**Severity:** Minor

### 36. `wifi.yaml` and `wifi__bssid.yaml` differ only by adding `bssid: !secret wifi__bssid` and `power_save_mode: none`

**Where:** `includes/wifi.yaml` vs `includes/wifi__bssid.yaml`. Diff is two lines (lines 18, 28 in `wifi__bssid.yaml`).
**Suggested fix:** Single `wifi.yaml` with optional `${bssid_secret: ""}` substitution and `${power_save_mode: ""}`. Empty default → no key emitted.
**Effort:** M
**Severity:** Minor

### 37. Filename `wifi__bssid.yaml` has double underscore (typo-prone)

**Where:** `includes/wifi__bssid.yaml`. Note also the underlying secret is `wifi__bssid` (also double underscore) per `secrets.yaml:13`. Comment in secrets.yaml has typo `wifi__bssod.yaml` (item 6).
**What:** Double underscore is unusual and easy to mistype. Also: ESPHome convention for files like `i2c_bme68x_bsec2.yaml` uses single underscore.
**Suggested fix:** Rename to `wifi_bssid.yaml` (single underscore); rename secret to `wifi_bssid` matching.
**Effort:** S
**Severity:** Cosmetic

---

## H. MQTT / api / logger include hygiene

### 38. `mqtt.yaml` and `mqtt_with_rtttl.yaml` differ in `keepalive` and `on_message:` block

**Where:** `includes/mqtt.yaml:17` adds `keepalive: 60s` (added 2025-12-18 per changelog); `mqtt_with_rtttl.yaml` lacks it. `mqtt_with_rtttl.yaml:25-33` has `on_message:` block; `mqtt.yaml` has it commented.
**What:** Drift between two near-identical files. The `keepalive: 60s` fix in `mqtt.yaml` was not propagated to `mqtt_with_rtttl.yaml` (which is the one actually loaded by 7 of 11 PROD devices).
**Suggested fix:** Either sync `mqtt_with_rtttl.yaml` to add `keepalive: 60s`, or merge to one file driven by substitution `${mqtt_extras: empty|rtttl}` (cross-ref item 14).
**Effort:** S
**Severity:** Notable (real config drift)

### 39. `mqtt.yaml` has 6 lines of commented `on_message: log_level_set` actions referenced as `mqtt_on_message/log_level_set.yaml`

**Where:** `includes/mqtt.yaml:32-37`. Note: `mqtt_on_message/log_level_set.yaml` does exist (`includes/mqtt_on_message/`).
**What:** "Do not include — causes OTA slow" warning at line 31. Dead code preserved for context but clutters.
**Suggested fix:** Move to `inbox`-style note in AGENTS.md: "log-level-via-mqtt is known broken, do not use". Delete the commented include lines.
**Effort:** S
**Severity:** Cosmetic

### 40. `api.yaml` and `api_services.yaml` and `api_services__water.yaml` — three near-identical copies

**Where:** Diff between `api.yaml` (5 lines) → `api_services.yaml` (~25 lines, adds `services:` with scan_wifi) → `api_services__water.yaml` (~50 lines, adds `services: scan_wifi + set_total_water + add_total_water`, plus `on_client_connected:` lambda).
**What:** Each is a strict superset of the previous. Three files per "feature flag".
**Suggested fix:** Single `api.yaml` driven by `${api_services: empty|generic|water}` substitution that toggles which include packages get pulled in. Or `packages: { api_water: !include api_services__water.yaml }` and similar.
**Effort:** M
**Severity:** Minor

### 41. `api_password` is defined in `secrets.yaml:27` and `secrets_example.yaml:25` but only commented out in `api.yaml:8` and `api_services.yaml:12`

**Where:** Comment on the secret says `# this is obsolete and deprecated`. Yet still in secrets.
**Suggested fix:** Remove from `secrets.yaml` and `secrets_example.yaml`. The encryption `key:` is the modern auth.
**Effort:** S
**Severity:** Cosmetic
**Status:** ✅ done 2026-05-11 (removed `# password:` lines from api.yaml/api_services.yaml/api_services__water.yaml; commented `api_password` in secrets.yaml + secrets_example.yaml — kept for reference per Pawelo's call)

### 42. `web_username` / `web_password` defined in secrets but auth block is commented in both web_server files

**Where:** `secrets.yaml:28-29`, `secrets_example.yaml:27-28`; `includes/web_server.yaml:14-16` (commented), `web_server_basic.yaml:14-16` (commented).
**What:** Secrets exist but are unused.
**Suggested fix:** Either enable web auth (set `auth:` block), or remove the unused secrets.
**Effort:** S
**Severity:** Cosmetic
**Status:** ✅ done 2026-05-11 (removed commented `auth:` block from web_server.yaml + web_server_basic.yaml; commented `web_username`/`web_password` in secrets.yaml + secrets_example.yaml — kept for reference per Pawelo's call)

### 43. `logger.yaml` comments mix mqtt-component logging level overrides with unrelated component overrides

**Where:** `includes/logger.yaml:18-25` — `mqtt.component: INFO`, `mqtt.client: INFO`, `component: ERROR`, `tcs34725: ERROR`, `weact_2.90_3c: WARN`, `sgp30: WARN`. `logger_level.yaml:13-33` has a slightly different list with same intent but extra entries (`mqtt: INFO`, `mqtt.idf: INFO`, `sensor: INFO`, `i2c: INFO`, `i2c.idf: INFO`).
**What:** Two files, divergent log-level lists. Devices loading `logger.yaml` (default) vs `logger_level.yaml` (override) get different per-component log filtering.
**Suggested fix:** Pick one canonical list, sync. Cross-ref item 15.
**Effort:** S
**Severity:** Minor

---

## I. Board file inheritance & edge cases

### 44. `board_esp8266.yaml` and `board_esp32.yaml` and `board_esp32_with_psram_fix.yaml` and `board_esp32__water_pump.yaml` and `board_esp32_variant.yaml` and `board_esp32__esp-idf.yaml` and `board_miniss_bk7231n.yaml` — 7 board files, partially overlapping

**Where:** `includes/board_*.yaml`.
**What:** Each board file is a near-copy of `board_esp32.yaml` with minor variations (PSRAM fix, water-pump globals, ESP32 variants without minimum_chip_revision, ESP-IDF specific, BK7231N specific). Total ~35KB of nearly-duplicated YAML across these 7 files.
**Why fix:** Same change in upstream ESPHome (e.g., new flag) needs to be applied to 7 files. Already showing drift — `board_esp32__esp-idf.yaml` has `sdkconfig_options:` populated (line 48-71) while `board_esp32.yaml` has them commented out.
**Suggested fix:** Identify the shared base (esphome:, preferences:, framework:, the !include chain) and the per-variant deltas (sdkconfig_options for ESP-IDF, platformio_options for PSRAM fix, globals for water pump). Refactor to `board_base.yaml` + per-variant `board_<variant>.yaml` that pulls the base via `<<: !include` and adds only its specifics. Big change.
**Effort:** L
**Severity:** Notable

### 45. `board_esp32__esp-idf.yaml` and `board_esp32.yaml` — `sdkconfig_options` block duplicated, drifted

**Where:** `board_esp32.yaml:42-83` has `sdkconfig_options:` mostly commented; `board_esp32__esp-idf.yaml:48-71` has same block uncommented and slightly modified. Both files are loaded conditionally per device (esp32-39 has `# <<: !include { file: ../includes/board_esp32__esp-idf.yaml, vars: {} }` commented at line 82).
**What:** Two source files for "the same" sdkconfig settings.
**Suggested fix:** Move sdkconfig_options to `2_PROD/sdkconfig.defaults` (already exists, see esp32-35 build) and reference from one board file.
**Effort:** M
**Severity:** Minor

### 46. `board_miniss_bk7231n.yaml` does not include `mqtt.yaml` — comments say it cannot be overridden

**Where:** `includes/board_miniss_bk7231n.yaml:36-37` — `#! as mqtt cannot be overwritten later in the code need to include in in each script (to facilitate "on_message" customization)` and `#<<: !include mqtt.yaml`.
**What:** This is a special case where the override-by-order pattern doesn't work for BK7231N. Needs documentation in AGENTS.md.
**Suggested fix:** Document the exception in AGENTS.md "How overrides work" section (cross-ref P0-2).
**Effort:** S
**Severity:** Minor

### 47. CLIO blind spot: transitive double-board inclusion

**Where:** Theoretical — if a device file did `<<: !include board_esp8266.yaml` and any other top-level include eventually pulled in `board_esp32.yaml`. This isn't currently the case in any PROD device, but it's not prevented either.
**What:** Both board files define `esphome:`, `preferences:`, and the wifi/api/ota/logger chain. Per first-key-wins, the **first-included** board's `esphome:` block would win, and the second one's would be silently dropped. The platform-specific block (`esp8266:` vs `esp32:`) would coexist (different keys), causing config validation errors at compile time.
**Failure mode:** Compile-time error like `"Cannot have both esp32: and esp8266: blocks"` from ESPHome validation. So failures are loud, not silent.
**Mitigation present:** None proactive. The shape grep from P0-1 wouldn't catch a transitive double-board; it counts top-level merge keys but not what they pull in.
**Suggested fix:** Add a pre-commit hook or a step in `upgrade/SOP_upgrade.md` that resolves all `!include`s and checks no device pulls in two `board_*.yaml` files transitively. Pseudocode: walk includes recursively, collect all `board_*.yaml` files reached, error if count > 1.
**Effort:** M
**Severity:** Minor (hypothetical, but worth a 30-line script for safety)

### 48. `board_esp32__esp-idf.yaml` filename has double-underscore separator

**Where:** `includes/board_esp32__esp-idf.yaml`, `includes/board_esp32__water_pump.yaml`, `includes/api_services__water.yaml`, `includes/api_services__water.yaml`, `interfaces/fram__water_pump.yaml`, `interfaces/nvm_fram_i2c__water_pump.yaml`. Other naming style with `_` single separator: `board_esp32_with_psram_fix.yaml`, `board_esp32_variant.yaml`.
**What:** Two conventions for "compound name with variant suffix": `board_esp32__variant` (double underscore = "variant") and `board_esp32_variant` (single underscore = continuation). Inconsistent.
**Suggested fix:** Pick one. Recommend single underscore (matches AGENTS.md `category_specific_name.yaml`).
**Effort:** S
**Severity:** Cosmetic

### 49. Board file comments still show `OLD notation` line that has been irrelevant for years

**Where:** `includes/board_esp8266.yaml`, `board_esp32.yaml`, `board_esp32_variant.yaml`, `board_esp32__esp-idf.yaml`, `board_esp32_with_psram_fix.yaml`, `board_esp32__water_pump.yaml`, `board_miniss_bk7231n.yaml` — every board file has `#  platform: ESP8266   # OLD notation` near `comment:`.
**What:** Reminder of pre-2022 ESPHome syntax, now decade-stale.
**Suggested fix:** Delete the line everywhere.
**Effort:** S
**Severity:** Cosmetic

---

## J. GPIO / hardware opacity

### 50. Pin GPIO numbers hardcoded in PROD without "what's connected" comment

**Where:** Many. Examples:
- `2_PROD/esp12f-10_Office.yaml:81` — `<<: !include { file: ../interfaces/i2c.yaml, vars: { bus_id: "bus_a", sda: "GPIO4", scl: "GPIO0" } }` — no comment on what's on the bus.
- `2_PROD/esp12f-10_Office.yaml:126` — `- !include { file: ../outputs/led.yaml, vars: { ix: "", gpio: "GPIO10", inverted: false } }` — comment says "LED" but doesn't say which physical LED.
- `2_PROD/esp12f-21_Underfloor.yaml:84` — `gpio: "GPIO14"` for one_wire — no comment on physical wiring.
**What:** Pinouts are referenced in header comments via `file://../pinouts/...`, but per-include line lacks "wire is on terminal X". Forces opening the device, the pinout image, and reading it.
**Suggested fix:** Add inline comment on each interface/output include with what's physically connected (e.g., `# GPIO4 = top relay on AVT5713 board, GPIO5 = bottom relay`).
**Effort:** L (per device, but cumulative — could be done lazily)
**Severity:** Cosmetic

### 51. ESP8266 reserved-pin warnings repeated in every PROD file header

**Where:** `2_PROD/esp12f-10_Office.yaml:5-6`, `esp12f-11_Entrance_Entry.yaml:5-6`, `esp12f-15_Upstairs.yaml:5-6`, `esp12f-21_Underfloor.yaml:5-6`, `esp12f-25_AquariumWindow.yaml:5-6` — `# NOTE: pin 9 do not work (it hangs ESP) - reserved for flashing; # NOTE: pin 10 - use with caution, read https://www.letscontrolit.com/forum/viewtopic.php?t=1462`.
**What:** Same note copy-pasted 5 times. Already in AGENTS.md "GPIO and Hardware Conventions" section.
**Suggested fix:** Remove from per-device headers; rely on AGENTS.md.
**Effort:** S
**Severity:** Cosmetic

### 52. I2C addresses hardcoded across many PROD files (cross-device drift)

**Where:** `0x44` for SHT3x in many places, `0x77` for BME680, `0x76` for BME280, `0x23` for BH1750, `0x62` for SCD40, `0x29` for TCS3472. These are hardware-fixed addresses, but they're hardcoded without a reference.
**What:** No central table of "BH1750 = 0x23". Adding a new sensor requires checking the datasheet.
**Suggested fix:** Add an `addresses:` table to AGENTS.md mapping sensor → address(es).
**Effort:** S
**Severity:** Cosmetic

### 53. `inverted:` substitution misuse — `"false"` as string vs `false` as boolean

**Where:** `2_PROD/esp12f-10_Office.yaml:46` → `restore_from_flash: "false"  # must be set as string to work` (comment acknowledges the quirk). But `outputs/led.yaml:12` has `inverted: ${inverted}` which receives boolean values like `false` (no quotes) from `2_PROD/esp12f-10_Office.yaml:126` `inverted: false`.
**What:** Mix of "must be string" and "must be boolean". Documented for `restore_from_flash` but not for `inverted`. Reader has to remember which is which.
**Suggested fix:** Document in AGENTS.md.
**Effort:** S
**Severity:** Cosmetic

---

## K. Dead / commented-out code

### 54. `mqtt_with_rtttl.yaml` has 6 lines of commented `log_level_set` includes

**Where:** `includes/mqtt_with_rtttl.yaml:34-40`. Already covered in item 39.
**Severity:** Cosmetic

### 55. `board_esp32.yaml` has 30+ lines of commented `sdkconfig_options:`

**Where:** `includes/board_esp32.yaml:43-83`. Drifted from `board_esp32__esp-idf.yaml:48-71`.
**Suggested fix:** Decide: either uncomment and use, or delete. Cross-ref item 45.
**Effort:** S
**Severity:** Minor

### 56. `2_PROD/esp32-35_Pump_Garage.yaml` has commented "test" template sensors at lines 159-178

**Where:** `2_PROD/esp32-35_Pump_Garage.yaml:159-178` — `#! for test purpose only` block with 6 commented template sensors testing global variables.
**Suggested fix:** Move to `0_DEV/` if still relevant, delete from PROD.
**Effort:** S
**Severity:** Cosmetic
**Status:** ❌ cancelled 2026-05-11 — Pawelo keeps the commented test sensors in place as reference

### 57. `2_PROD/esp32-35_Pump_Garage.yaml:79-99` has commented `on_boot:` priority -100 block

**Where:** `includes/board_esp32__water_pump.yaml:78-98` — 20 lines of commented `on_boot:` priority -100. Comment says `# NOTE: MOVED to api on_client_connected`.
**Suggested fix:** Delete; the `api on_client_connected` lambda is in `api_services__water.yaml:30-46` and works.
**Effort:** S
**Severity:** Cosmetic

### 58. Header version-history comments in PROD files have grown to 30+ lines each

**Where:** `2_PROD/esp32-05_Shades_WinterGardenUpp.yaml:6-49` (44 lines of changelog), `esp32-35_Pump_Garage.yaml:6-58` (53 lines), `esp12f-10_Office.yaml:8-33` (26 lines).
**What:** "Pawelo, YYYYMMDD, ..." log per-file. After 4 years, dominates the file.
**Why fix:** Hard to find the actual config. Same info is recoverable via `git log`.
**Suggested fix:** Cap at last 10 entries; let `git log` carry the rest. Or move all changelog to a top-level CHANGELOG.md per device.
**Effort:** M
**Severity:** Minor

### 59. `2_PROD/esp32-35_Pump_Garage.yaml` has commented `external_components` blocks

**Where:** `2_PROD/esp32-35_Pump_Garage.yaml:339-349` — partial commented block of waveshare_epaper sources. Lines 343-348 commented while 347 active.
**Suggested fix:** Clean up; pick the active source, document the choice in a comment.
**Effort:** S
**Severity:** Cosmetic

### 60. `2_PROD/esp32-05_Shades_WinterGardenUpp.yaml:260-273` has commented external_components and the page_time `lambda` block at lines 309-419 is entirely commented (~110 lines)

**Where:** `2_PROD/esp32-05_Shades_WinterGardenUpp.yaml`.
**What:** Commented-out display page with extensive `lambda:` code. ~110 lines of dead code.
**Suggested fix:** Either delete (history is in git), or move to a `0_DEV/<device>_alt_pages.yaml` reference.
**Status:** ✅ done 2026-05-11 (deleted commented epaper_spi external_components block + 111-line commented page_time lambda; history in git)
**Effort:** S
**Severity:** Cosmetic

---

## L. Naming convention violations

### 61. Output ID convention `o_led${ix}` vs sensor ID convention `lux${ix}` — different prefix discipline

**Where:** `outputs/led.yaml:7` → `id: o_led${ix}`. `outputs/relay.yaml:9` → `id: relay_${ix}` (note: relay_, not o_relay). `outputs/door.yaml` → `id: o_door${ix}` (per usage in `covers/door_cover.yaml:14`). Sensors: `lux${ix}`, `temp${ix}`, `hum${ix}` (no prefix).
**What:** Inconsistent prefix:
- outputs use `o_` for led, door (but not relay)
- relays use `relay_` (no o_ prefix)
- switches use `s_relay${ix}` (with `s_` prefix; `switches/relay.yaml:14`)
- buttons use no prefix
- sensors use no prefix
- lights use no prefix (they reference outputs by ID)
**Suggested fix:** Pick one convention (e.g. `o_<name>` for outputs, `s_<name>` for switches, plain for sensors). Sweep.
**Effort:** L
**Severity:** Minor

### 62. `globals_water_totals_restore.yaml` defines `global_water_total_*` (with underscore); `board_esp32__water_pump.yaml` defines `global_watertotal_*` (no underscore)

**Where:** Cross-ref item 7.
**Severity:** Notable (covered in item 7)

### 63. Polish-source comment string `"Pawelo, YYYYMMDD, ..."` is the changelog format vs README/AGENTS.md English conventions

**Where:** Every file changelog. Comments themselves are in English.
**What:** "Pawelo" is the author tag (acceptable). Format works.
**Severity:** Cosmetic — acceptable, not worth fixing.

### 64. `secrets.yaml:43-49` has Polish + English comments mixed for Tuya devices

**Where:** `secrets.yaml:43` — `# TUYA device: , configuration as per: https://www.youtube.com/watch?v=WwQ2F873bb4`. Then lines 44-49 are device entries in English. The line at 41 has `# Pawelo, 20240907, set device_class and icon for sensor values` etc. AGENTS.md line 47 says "All YAML configuration files [...] must be written in English only". `secrets.yaml` is a YAML config file.
**What:** Compliant in English mostly, but the YouTube link points to Polish-language tutorial. Minor.
**Suggested fix:** Acceptable as-is. Optional: replace with English-language reference.
**Effort:** S
**Severity:** Cosmetic

---

## M. Pre-commit / lint coverage gaps

### 65. CLIO blind spot 1: pre-commit doesn't catch a malformed merge-key chain

**Where:** `.pre-commit-config.yaml`.
**What:** Current hooks: `check-yaml --unsafe`, `yamllint` (with `key-duplicates: disable`), `trailing-whitespace`, `end-of-file-fixer`, `check-added-large-files`, `check-merge-conflict`, `check-case-conflict`, `detect-private-key`, `check-executables-have-shebangs`, `check-shebang-scripts-are-executable`, `ggshield`, `gitleaks`.

What's missing for the override-by-order pattern:
- (a) **Shape check** — count top-level `<<: !include` per device file; flag files where count is 0 (likely: every PROD should have ≥1 board include) or unexpectedly high. This is the upgrade/SOP_upgrade.md grep promoted to a hook.
- (b) **Merge-key syntax check** — the `<<:` line must be followed by `!include ...`, not by any other YAML mapping. Yamllint with `key-duplicates: disable` doesn't enforce this.
- (c) **Reference resolution check** — every `!include` path resolves to an existing file with matching case (catches items 2, 3).

**Suggested fix:** Three small custom local hooks (Python scripts in `tools/`), each ~30 lines. Plug into `.pre-commit-config.yaml` as `repo: local`. Cross-ref items 69, 70.
**Effort:** M
**Severity:** Notable

### 66. `yamllint` has `key-duplicates: disable` — intentional but blocks an entire category of bugs

**Where:** `.yamllint:5`. Comment in `.pre-commit-config.yaml:3` confirms intent.
**What:** Disabled because the override-by-order pattern uses multiple `<<:` keys. But this also disables detection of accidental duplicate plain keys (e.g., two `wifi:` blocks at top level — actually rejected by ESPHome's loader, but yamllint won't even warn).
**Suggested fix:** Switch `yamllint` rule to `forbid-implicit-octals: false; key-duplicates: {forbid: true, ignore-patterns: ['^<<:$']}` — but this isn't a yamllint feature out of the box. Or write a custom hook (item 65 b).
**Effort:** M
**Severity:** Minor

### 67. `yamllint` rule `truthy: { check-keys: false }` may hide typos in yes/no fields

**Where:** `.yamllint:6-7`. Allows `true: ...` as a key (probably won't happen, defensive).
**What:** Usually harmless. ESPHome configs use `true`/`false` as values, not keys. The setting is overcautious.
**Suggested fix:** Re-enable `check-keys: true` (default).
**Effort:** S
**Severity:** Cosmetic

### 68. `yamllint indent-sequences: whatever` allows inconsistent indentation across PROD files

**Where:** `.yamllint:9`. Some PROD files indent sequences 0 spaces (just `- !include ...` at column 0), others 2 spaces.
**What:** Mixed style allowed by `whatever`. Hurts readability.
**Suggested fix:** Set to `consistent` and run `yamllint --fix` (where supported). Or `indent-sequences: true`.
**Effort:** M
**Severity:** Cosmetic

### 69. CLIO minor 4: P0-1 grep snippet edge case

**Where:** `upgrade/SOP_upgrade.md` section "Step 5: Pre-Flight Checks" — also the prior audit's P0-1 grep `grep -c '^<<: !include' "$f"`.
**What:** Tested against actual PROD files. The grep correctly counts top-level (zero-indent) merge-key lines. I confirmed via `grep -E '^[ \t]+<<: !include' 2_PROD/*.yaml` that **no** PROD file has indented `<<: !include` lines (count = 0). So the regex `^<<: !include` is correct for the current repo.

However, if an `<<: !include` line is ever placed inside a block (e.g., inside `i2s_audio:` block at `2_PROD/esp32-14_Salon.yaml:111-112` — which is `- <<: !include {...}`, list item not top-level mapping merge), it would not be counted, which is correct. But if a future refactor puts `<<: !include` two-spaces-indented as a sub-key of `esphome:`, the grep would silently miss it. Recommend tightening to `^<<:[[:space:]]*!include` (handles tabs) and adding a "if grep returns 0 it's an anomaly" assertion.

**Suggested fix:** Change `grep -c '^<<: !include' "$f"` to `grep -cE '^<<:[[:space:]]+!include'` and add: `if [ "$count" -eq 0 ]; then echo "WARNING: $f has no top-level <<: !include"; fi`.
**Effort:** S
**Severity:** Minor

### 70. P0-1 grep is in a markdown SOP file, not a runnable hook

**Where:** `upgrade/SOP_upgrade.md` only — the shape check runs only at upgrade time.
**What:** Manual SOP grep won't catch a regression made between upgrades.
**Suggested fix:** Promote to a `tools/check_shape.py` script + `.pre-commit-config.yaml` local hook. Run on every commit. ~20 lines.
**Effort:** M
**Severity:** Minor

### 71. `yamllint` configured but `check-yaml` from `pre-commit-hooks` runs before it — duplicates work

**Where:** `.pre-commit-config.yaml:6-26`. `check-yaml --unsafe` (PyYAML) parses the file, then `yamllint` parses again.
**What:** Two YAML parses per commit per file. Acceptable cost (small files).
**Suggested fix:** Consider dropping `check-yaml` since `yamllint` is stricter and handles `--unsafe`-equivalent (custom-tag tolerance) via its config. Or keep both for defense in depth.
**Effort:** S
**Severity:** Cosmetic

---

## N. Secrets handling

### 72. CLIO blind spot 2: `secrets.yaml` is gitignored but not separated from `secrets_example.yaml`

**Where:** `.gitignore:4` → `/secrets.yaml`. Confirmed via `git check-ignore -v secrets.yaml` (output: `.gitignore:4:/secrets.yaml`). Confirmed via `git ls-files | grep -i secret` only `includes/secrets.yaml` (the wrapper) and `secrets_example.yaml` are tracked. **`/Users/pawelo/dev/esphome_scripts/secrets.yaml` is NOT in git history** (`git log --all -- secrets.yaml` returns empty).

Per-device files `0_DEV/.gitignore:5` → `/secrets.yaml` and `2_PROD/.gitignore:5` → `/secrets.yaml`. The on-disk `0_DEV/secrets.yaml` is a symlink to `../secrets.yaml` so it's a single source.

**What:** Secrets management is correct. All wifi/api/mqtt files use `!secret name` properly. No plaintext credentials in any tracked YAML file.

**Verdict:** Pass. Cross-ref items 41, 42 for unused secrets.
**Effort:** N/A (verified, no fix needed)
**Severity:** N/A — included as an entry per brief request.

### 73. `secrets.yaml` contains MQTT credentials with empty values

**Where:** `secrets.yaml:36-37` — `mqtt_user: ""` and `mqtt_password: ""`. Same in `secrets_example.yaml:31-32`.
**What:** No MQTT auth. Anyone on the LAN can publish/subscribe to the broker.
**Why fix:** Network security if MQTT broker is reachable beyond LAN. For a homelab with isolated VLAN, acceptable.
**Suggested fix:** If MQTT broker is on a trusted segment, fine. Otherwise enable auth.
**Effort:** S (+ Mosquitto config)
**Severity:** Minor (depends on threat model)

### 74. `secrets.yaml` contains plaintext Tuya `local_key` values

**Where:** `secrets.yaml:43-49` — `pss-201 ... C^KORx8;T6(Oxf^;`, `pss-202 ... V>M*)^Dz};FfsA4&`, etc. These are Tuya device local_key values and the comment says "configuration as per [YouTube tutorial]".
**What:** Plaintext secrets in `secrets.yaml`. File is gitignored, so risk is local-only (someone with shell access).
**Suggested fix:** As-is is fine for gitignored secrets. If the file ever becomes unmistakenly tracked (item 75), this is critical.
**Effort:** N/A
**Severity:** Cosmetic (current state OK)

### 75. `gitleaks` and `ggshield` are in pre-commit but `detect-private-key` is the only `pre-commit-hooks` secret-detection

**Where:** `.pre-commit-config.yaml:15` (`detect-private-key`), lines 28-34 (`ggshield secret scan`), lines 36-39 (`gitleaks`).
**What:** Defense in depth. Three layers. Good.
**Verdict:** No action needed — secrets handling is robust at commit time.
**Effort:** N/A
**Severity:** N/A — flagged as positive observation

### 76. `secrets.yaml:30-34` has commented-out alternative MQTT IPs

**Where:** `secrets.yaml:30,32,34` — `#mqtt_ip: "192.168.1.72"`, `# mqtt_ip: "mqtt.lan"`, `#mqtt_ip: "test.mosquitto.org"`. Active line is `mqtt_ip: "192.168.1.100"`.
**What:** The `test.mosquitto.org` reference is a public broker. If accidentally uncommented, devices would publish to an open public broker.
**Suggested fix:** Remove the public-broker line. Keep only LAN options.
**Effort:** S
**Severity:** Minor (if uncommented = data leak)

---

## O. Documentation drift

### 77. `AGENTS.md` does not document the override-by-order rule (cross-ref P0-2 in prior audit)

**Where:** `AGENTS.md` "YAML Structure" section lists Override includes as step 4, but doesn't explain the first-key-wins rule.
**Suggested fix:** Add a "How overrides work" subsection. Cross-ref P0-2 in prior audit. (Already in the audit recommendations — flagging here as a numbered KANBAN-able item.)
**Effort:** S
**Severity:** Notable (P0 in prior audit)

### 78. `AGENTS.md` mentions categories `sensors/`, `outputs/`, `lights/`, etc. but doesn't list the file naming rule for `set_*.yaml` packages

**Where:** `AGENTS.md` § Folders Structure (lines 199-211).
**What:** Repo has `buttons/set_apple_tv_ir_remote.yaml`, `i2s/set_i2s_media_player.yaml`, `covers/set_door_cover.yaml`, etc. The `set_*` prefix means "package for `packages:` block". Not documented.
**Suggested fix:** Add convention to AGENTS.md § File Naming Conventions: "Files prefixed `set_*` are designed for use in `packages:` blocks; they include their parent `cover:`, `button:`, `media_player:` etc. block at the top."
**Effort:** S
**Severity:** Minor

### 79. `README.md` has typo "Futures" instead of "Features"

**Where:** `README.md:11`.
**Suggested fix:** Fix typo.
**Effort:** S
**Severity:** Cosmetic
**Status:** ✅ done 2026-05-11

### 80. `AGENTS.md` "Build and Flash Commands" example uses old shorthand

**Where:** `AGENTS.md:13` — `esphome -s devicename esp12f_office -s updates 30s -s room Office -s mqtt_room office run 2_PROD/esp12f-10_Office.yaml`. Modern aliases are documented in `.dir_aliases` (loaded by zsh) and the actual flashing happens via `esp10` shell alias, not the long-form esphome CLI invocation.
**Suggested fix:** Lead with the alias example, push the long-form to a "without aliases" subsection.
**Effort:** S
**Severity:** Cosmetic

### 81. `upgrade/COMPONENTS.md:31` says "Min version pins in configs | 2025.6.3 – 2025.8.0" but the table at line 36-39 only lists 3 devices (cross-ref item 8)

**Where:** `upgrade/COMPONENTS.md:36-39` correctly lists the 3 devices that have `esphome_min_version`. But the implication is that "all configs are pinned somewhere in the 2025.6.3-2025.8.0 range" — actually 8 of 11 are unpinned.
**Suggested fix:** Update COMPONENTS.md table to clarify "3 of 11 PROD configs declare `esphome_min_version`. 8 are unpinned and rely on the venv version."
**Effort:** S
**Severity:** Cosmetic

---

## P. Misc / cosmetic

### 82. `2_PROD/.gitignore` and `0_DEV/.gitignore` and `1_UAT/.gitignore` are duplicates

**Where:** All three contain the same 5 lines (`# Gitignore settings for ESPHome / # This is an example...`).
**What:** Three identical files, none with custom rules.
**Suggested fix:** Consolidate to repo root `.gitignore` (already covers `/.esphome/` and `/secrets.yaml`). Remove the per-folder copies.
**Effort:** S
**Severity:** Cosmetic

### 83. `1_UAT/` has only a `.gitignore` and no actual configs

**Where:** `1_UAT/.gitignore` only.
**What:** Empty UAT tier. The repo has `0_DEV/`, `1_UAT/`, `2_PROD/` workflow per `AGENTS.md:202-204`, but UAT is unused.
**Suggested fix:** Either delete `1_UAT/` and document the simplified DEV→PROD flow in AGENTS.md, or commit to using it for staging.
**Effort:** S
**Severity:** Cosmetic

### 84. `docs/` directory exists but content not audited

**Where:** `docs/` directory with one subfolder. Not part of brief scope but worth flagging if docs there reference deprecated file paths.
**Suggested fix:** Audit if not already. Out of scope for this enumeration.
**Effort:** S
**Severity:** Cosmetic

### 85. `re_codes_captured.csv` (31KB) at repo root is a captured-IR-codes log, not config

**Where:** `re_codes_captured.csv`.
**What:** Reference data, not a config. Lives at root rather than in `pinouts/` or `docs/`.
**Suggested fix:** Move to `docs/ir_codes/captured.csv` or similar. Or to `2_PROD/.references/`.
**Effort:** S
**Severity:** Cosmetic

### 86. `Inventory.md` (19KB) at repo root vs `upgrade/COMPONENTS.md` (similar content)

**Where:** Two large component-inventory files. Likely overlap in content.
**Suggested fix:** Audit overlap, consolidate or cross-link explicitly.
**Effort:** M
**Severity:** Cosmetic

---

## Summary table

### Count by severity × category

| Category | Cosmetic | Minor | Notable | Important | Total |
|----------|----------|-------|---------|-----------|-------|
| A. Filename casing | 2 | 0 | 1 | 1 | 4 |
| B. Real bugs | 1 | 0 | 2 | 0 | 3 |
| C. esphome_min_version | 0 | 1 | 2 | 1 | 4 |
| D. Override / packages | 0 | 6 | 0 | 0 | 6 |
| E. Boilerplate duplication | 5 | 1 | 0 | 0 | 6 |
| F. Substitution / metadata | 6 | 3 | 0 | 0 | 9 |
| G. Wifi includes | 2 | 3 | 0 | 0 | 5 |
| H. MQTT / api / logger | 3 | 2 | 1 | 0 | 6 |
| I. Board file inheritance | 3 | 2 | 1 | 0 | 6 |
| J. GPIO / hardware | 4 | 0 | 0 | 0 | 4 |
| K. Dead code | 5 | 2 | 0 | 0 | 7 |
| L. Naming violations | 2 | 1 | 1 (cross-ref) | 0 | 4 |
| M. Pre-commit / lint | 3 | 3 | 1 | 0 | 7 |
| N. Secrets handling | 2 | 2 | 0 | 0 | 5 (incl. 1 verdict-only entry) |
| O. Documentation drift | 4 | 1 | 1 | 0 | 6 |
| P. Misc / cosmetic | 5 | 0 | 0 | 0 | 5 |
| **Total** | **47** | **26** | **10** | **2** | **86** (incl. 1 verdict-only entry) |

### Total estimated effort (sum of S/M/L)

Counting by entry tag (S=≤15min, M=≤1h, L=>1h, N/A=0):
- **S** items: 49 → ~12 hours (avg 15 min)
- **M** items: 22 → ~22 hours (avg 60 min)
- **L** items: 8 → ~24 hours (avg 3 hr)
- **N/A** items (verdict-only, no fix): 4 → 0 hours

**Total estimated effort: ~58 hours**

Realistic phasing recommendations (Pawelo's call):
- **Phase 1 — High-leverage 15min hits** (items 5, 6, 9, 19, 25, 41, 42, 53, 56, 57, 60, 76, 79): ~3 hours, fixes the real bugs and the unused-secret risks.
- **Phase 2 — Sweep medium fixes** (items 8, 10, 13, 14, 15, 16, 17, 25, 33, 34, 35, 38, 40, 43, 65, 70): ~12 hours, addresses overrides, sub drift, pre-commit gaps.
- **Phase 3 — Big ones, defer until other touch happens** (items 1, 2, 12, 18, 44, 50, 58, 61): ~25 hours, only if doing a full repo sweep.
- **Phase 4 — Cosmetic only** (everything else): pick off opportunistically.

## Key Takeaways

> The repo is mature and well-structured (per the prior strategic audit's verdict), but cross-machine portability has rotted: ~139 case-mismatch `!include` references between PROD/DEV YAML and on-disk filenames mean every PROD file would fail to compile on a case-sensitive Linux/CI runner. macOS HFS+ hides the breakage. The single biggest action that closes most of the risk in this enumeration is items 1+2 (sweep the case mismatch) — that single fix unlocks future Linux dashboard / GitHub-Actions migration. Outside that, the `esphome_min_version` substitution is set on 3 files but actually consumed only on 1 (item 9 — silent failure). The override-by-order pattern is correct (per the prior audit) but the migration debt to `packages:` is real (items 12-17). Pre-commit hook coverage of the override pattern is the biggest blind spot from CLIO's review (item 65) and is worth ~30 lines of Python in `tools/`. Secrets handling is robust — gitignored, all `!secret` references, three layers of pre-commit secret-detection (item 75). No critical items, two Important items (case mismatch, esphome_min_version not consumed). Phased fix plan in summary table.

## Sources

- `~/dev/esphome_scripts/AGENTS.md`
- `~/dev/esphome_scripts/.yamllint`
- `~/dev/esphome_scripts/.pre-commit-config.yaml`
- `~/dev/esphome_scripts/.gitignore`
- `~/dev/esphome_scripts/secrets.yaml`, `secrets_example.yaml` (live read)
- `~/dev/esphome_scripts/2_PROD/*.yaml` (all 11)
- `~/dev/esphome_scripts/0_DEV/esp01s_1r_x__F.yaml`, `esp32_dev.yaml`, others (representative)
- `~/dev/esphome_scripts/includes/*.yaml` (all 38)
- `~/dev/esphome_scripts/interfaces/*.yaml`
- `~/dev/esphome_scripts/sensors/*.yaml` (filename inventory)
- `~/dev/esphome_scripts/buttons/`, `outputs/`, `lights/`, `switches/`, `covers/` (representative samples)
- `~/dev/esphome_scripts/upgrade/SOP_upgrade.md`, `COMPONENTS.md`, `README.md`
- `~/dev/esphome_scripts/README.md`
- Prior audit: `~/Documents/PKA/inbox/dex_esphome_repo_review.md`
- Prior CLIO review embedded in the prior audit (3 blind spots, 3 minor evidence gaps)
- ESPHome loader source `esphome/yaml_util.py` referenced in prior audit (no re-read needed for this enumeration)

## Changelog

| Date       | Change                                                                            |
| ---------- | --------------------------------------------------------------------------------- |
| 2026-05-10 | Initial exhaustive enumeration by DEX — 86 entries, flat numbered, with TOC + summary. Closes CLIO blind spots (1=item 65; 2=items 72-76; 3=item 47) and CLIO minor evidence gaps (4=item 69; 5=item 10; 6=item 8). |
| 2026-05-10 | CLIO quality review appended — verdict: Pass to Pawelo. |

---

## Quality Review — ESPHome Strange Patterns Inventory
Reviewer: CLIO | Date: 2026-05-10 | Agent: DEX
Brief compliance: Pass

### What works

- **Format discipline holds across all 86 entries.** Every item has Where (file:line), What, Why fix (or omitted when self-evident), Suggested fix, Effort, Severity. TOC at top maps to category sections; summary table at bottom matches the body counts. Each entry is genuinely small enough to convert to a KANBAN card with no follow-up clarification — the actionability bar Pawelo asked for is met.
- **Evidence holds up to spot-checks.** Verified 9 items against the live repo: item 2 (case-mismatch — confirmed 32+ uppercase + 33 lowercase active mismatches in PROD alone, ~139 across PROD+DEV is plausible), item 3 (`bme68x_bsec2` sensor files genuinely don't exist on disk), item 5 (esp12f-21:122 malformed quote confirmed), item 8 (exactly 3 PROD files have `esphome_min_version`), item 9 (only `board_esp32_with_psram_fix.yaml` wires `min_version: ${esphome_min_version}` — silent failure for esp32-06 and esp32-35 is real), items 66-68 (yamllint config matches description), items 72-76 (`secrets.yaml` confirmed in `.gitignore:4`, `wifi.yaml` uses `!secret` throughout). No padding detected in Important/Notable tier — the two Important items are genuinely the highest-leverage fixes in the list.
- **CLIO blind spots are properly closed, not restated.** Item 47 (board inheritance) describes the actual failure mode (`Cannot have both esp32: and esp8266: blocks` at compile), notes failures would be loud not silent, and proposes a concrete 30-line walking-includes hook — answers the question rather than echoing it. Item 65 (pre-commit override coverage) breaks the gap into three named missing hook types (shape check, merge-key syntax, reference resolution) with clear scope. Items 72-76 (secrets) include verification commands (`git check-ignore`, `git ls-files`) and a positive verdict on item 75 with no make-work fix attached.
- **Phasing recommendation is honest.** The Phase 1 (~3h) / Phase 2 (~12h) / Phase 3 (~25h) / Phase 4 (opportunistic) split frames the 58h total realistically — Pawelo gets a "what to do this weekend" answer without a guilt trip about the 47 cosmetic items. Including verdict-only and positive-observation entries (72, 75) instead of forcing a fix is appropriate restraint.

### Issues to address

**Critical:** None.

**Minor:**
- **Item 28 (framework_type drift) lacks a clear "fix" verb.** The suggested fix is "add a one-line summary table to AGENTS.md" — fine, but the entry is more of an observation than an action. Could be merged into item 81 or the AGENTS.md drift cluster.
- **Item 33 (wifi variant audit) makes a sweeping "only commented references" claim across 6 files.** I didn't independently verify each line; if Pawelo wants this confidence-level it would help to have a one-line grep command embedded in the entry. Not blocking — the claim is consistent with what I sampled.
- **Item 50 effort tag "L (per device, but cumulative — could be done lazily)" mixes effort with phasing guidance.** Pure S/M/L would be cleaner; the lazy-execution note belongs in the Phase 4 description.
- **Item 25 appears twice in Phase 1 list and Phase 2 list.** (Search Phase 1: "items 5, 6, 9, 19, 25..." and Phase 2: "items 8, 10, 13, 14, 15, 16, 17, 25, 33...".) Probably a copy-paste residue from earlier phasing — pick one.
- **Severity labels in summary table column "Notable" for category L lists "1 (cross-ref)".** The cross-ref note is helpful but inconsistent with other rows that use bare counts. Cosmetic.

### Blind spots

The brief and prior audit are well-covered. No new blind spots surfaced — the deliverable mostly hits everything Pawelo would expect to see in an exhaustive inventory. Two thin areas worth noting (not blocking):

- **No entry on `0_DEV/` content quality.** Scope walked "representative `0_DEV/*.yaml`" per the deliverable's preamble, but findings from DEV files don't appear separately — they may be folded into PROD findings. If `0_DEV/` has its own patterns (orphan files, abandoned experiments), they're not listed. Pawelo can decide if that gap matters.
- **No entry on the `upgrade/` workflow itself beyond items 70 and 81.** The repo has `upgrade/SOP_upgrade.md`, `upgrade/COMPONENTS.md`, and the recent ESPHome upgrade pipeline note (`areas/esphome` per recent vault changelog). If those have inconsistencies (e.g., the upgrade SOP references files not in the current repo), they're not flagged. Out of scope per brief — flagged for awareness only.

### Recommendation

**Pass to Pawelo.**

The deliverable meets the brief in full. Evidence holds up to sampling. CLIO blind spots are genuinely closed with concrete answers. The phasing plan turns a wide-net 86-item enumeration into something Pawelo can act on this weekend without scope creep. Minor issues are housekeeping — the deliverable is fit for converting to KANBAN cards as-is.
