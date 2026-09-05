# ESPHome 2026.8.2 — Upgrade Impact for esphome_scripts

Covers changes from the last used version (**2026.5.3**, flashed 2026-06-14) to **2026.8.2** (latest stable, released 2026-08-31).
Use this file as a checklist when updating configs and reflashing devices.

> **Installed version:** 2026.8.2 (in `.venv`) — upgraded 2026-09-05
> **Versions covered:** 2026.6.0–5, 2026.7.0–4, 2026.8.0–2 (minor releases researched in detail; patches from GitHub release notes)
> **Rollout status (2026-09-05):** 6 of 11 PROD devices flashed and verified. **Blocked on 6 devices with old bootloaders — see Known Issue below.**

---

## Breaking Changes

Items that **may require config changes or verification** before reflashing. Verified against the actual repo (grep), not assumed.

| Change | Affects | Action required |
|--------|---------|----------------|
| **`select` component: deprecated `.state` accessor removed** (2026.7.0) | `0_DEV/esp32_dev_display.yaml` used `id(select_display_cycle_interval).state` (6 occurrences) — would have failed to compile on ≥2026.7.0 | **Fixed 2026-09-05** — replaced with `.current_option()`, same pattern already applied to `esp32-35_Pump_Garage.yaml` (2025-12-05 fix) |
| **ESP-IDF becomes default toolchain for ESP32** (2026.7.0) | All 6 ESP32 PROD devices | **No action** — every PROD device declares `framework_type:` explicitly (verified via grep). 4 already on `esp-idf` (Salon, Garden_Gateway, Shades, Attic); 2 still on `arduino` (Pump_Garage, Garage_Gate) — explicit, so the new default doesn't silently change anything. |
| **Web server v1 deprecated** (2026.7.0) | `esp12f-11_Entrance_Entry.yaml` has a `web_server.yaml` include line | **No action** — the include is fully commented out (`# <<: !include {file: ../web_server.yaml...}`). No PROD device currently runs web_server at all. |
| **NeoPixelBus deprecated on ESP32** (2026.6.0) | Salon RGB LED (GPIO48) | **No action** — active config uses `lights/led_rgb.yaml` (RMT-based). The alternate `lights/led_rgb_neopixelbus.yaml` include is commented out and unused — just don't re-enable it without checking its replacement. |
| **Light component: "preserve brightness on turn-off" behavior change** (2026.7.0) | Any `light:` entity with brightness (Salon RGB) | Low risk — verify Salon RGB LED behaves as expected after upgrade (brightness value on next turn-on may now equal last-set value instead of resetting). |
| **RC522 I2C default address changed** (2026.8.0) | Not applicable | Repo's RC522 reader is wired via **SPI**, not I2C (per COMPONENTS.md) — unaffected. |
| **Web server: entity_id format changed, `name_id` dropped, alarm_control_panel domain fix** (2026.8.0) | Not applicable | No PROD device has web_server or alarm_control_panel active. |
| **SGP4X/SEN5X/SEN6X sensor key rename** (`voc_index`/`nox_index`) | Not applicable | Repo uses **SGP30** and **ENS160**, not the SGP4X/SEN5X/SEN6X family — different component, unaffected. |
| **Modbus refactoring (client/server split, FC 0x17 signature change)** | Not applicable | No `modbus` component in this repo. |

### Quick verification commands

```bash
# Run from repo root before reflashing
grep -rn "\.state\b" --include="*.yaml" 0_DEV/esp32_dev_display.yaml | grep -v "^\s*#"
grep -rn "led_rgb_neopixelbus\|web_server\.yaml" --include="*.yaml" 2_PROD includes
grep -rn "framework_type:" 2_PROD/*.yaml   # confirm still explicit on all 6 ESP32 devices
```

---

## Known Issue — Old Bootloaders Block Safe OTA (discovered during rollout)

**Not a config/YAML issue — this is physical hardware state, invisible to grep or compile.**

During the actual flash rollout (2026-09-05), `esp32-39_Attic.yaml` OTA'd successfully (`OTA successful`, firmware accepted) but the device **never came back online** — not even after Pawelo power-cycled it physically. Router showed "Destination Host Unreachable" / no ARP entry, meaning it never reached WiFi association after reboot.

Root cause: the 2026.5.0 impact file (previous cycle) already flagged 5 devices with **old bootloaders lacking OTA rollback support**: `esp32-05`, `esp32-06`, `esp32-35`, `esp32-36`, `esp32-39`. That flag was never acted on (`esphome upload --bootloader` requires USB, deferred to "next physical access" — never happened). Without rollback support, if a new app image doesn't boot cleanly, the bootloader has no fallback slot to revert to — it just hangs. This is very plausibly what happened to Attic.

**Confirmed a 6th device shares this risk**: `esp32-14_Salon.yaml` printed on successful boot:
```
[W][app:193]: Bootloader too old for OTA rollback. Flash via USB once to update the bootloader
```
Salon's OTA happened to succeed this time, but it carries the identical exposure for any *future* OTA.

| Device | Status | Bootloader |
|--------|--------|-----------|
| `esp32-39_Attic` | 🔴 **Down** — OTA succeeded, device never rejoined network, survived power-cycle attempt. Needs USB recovery. | Old (no rollback) — confirmed by failure |
| `esp32-14_Salon` | 🟡 Flashed OK, running 2026.8.2 | Old (no rollback) — confirmed by boot-log warning |
| `esp32-05_Shades_WinterGardenUpp` | ⏸️ Not attempted | Old (no rollback) — per 2026.5.0 cycle note, unconfirmed on 2026.8.2 |
| `esp32-06_Garden_Gateway` | ⏸️ Not attempted | Old (no rollback) — per 2026.5.0 cycle note, unconfirmed on 2026.8.2 |
| `esp32-35_Pump_Garage` | ⏸️ Not attempted (also blocked separately by the override-farm drift, see below) | Old (no rollback) — per 2026.5.0 cycle note, unconfirmed on 2026.8.2 |
| `esp32-36_Garage_Gate` | ⏸️ Not attempted | Old (no rollback) — per 2026.5.0 cycle note, unconfirmed on 2026.8.2 |

**Action required before touching any of these 6 via OTA again:** physical USB session, run `esphome upload --bootloader 2_PROD/<device>.yaml` on each, starting with recovering Attic. Do this as one batch — same USB cable trip covers all 6.

---

## Known Issue — esp32 override farm drift (blocks Pump_Garage specifically)

`bash esphome-overrides/refresh.sh` failed (exit 1) after the pip upgrade: upstream `preferences.h` changed structurally between 2026.5.3 and 2026.8.2 (added RTC-backed preference storage, changed `make_preference` from inline to declared, added `load_from_key`/`make_backend_`). This is the header our private NVS/FRAM patch (PR#14119) modifies.

Only `esp32-35_Pump_Garage.yaml` uses this override (`external_components:` → `../esphome-overrides/esphome/components`) — confirmed via grep, no other PROD device is affected.

**Action required**: follow `upgrade/SOP_pr14119_refresh.md` Phase 2 — manually merge the upstream header changes into `esphome-overrides/esphome/components/esp32/preferences.h` (keep methods virtual), re-run `refresh.sh` until clean, flash-test on the `esp32-32` rig before touching production Pump_Garage. This is independent of the bootloader issue above but Pump_Garage needs *both* resolved before it can be safely reflashed.

---

## New Features Worth Exploring

Rated by relevance to this repo's architecture.

### High Relevance ★★★

| Feature | Why relevant | How to use |
|---------|-------------|-----------|
| **`ds248x` — OneWireBus over I2C** (2026.8.0, new component) | 6 PROD devices use GPIO-based `one_wire`/Dallas (DS18B20). If any device runs low on free GPIOs, DS248x bridges 1-Wire onto the existing I2C bus instead of a dedicated pin | Add `ds248x:` platform config, point `one_wire: platform: ds248x` at it — only worth it if a device needs to free up a GPIO pin |
| **`ld6002b` — 60GHz mmWave presence radar** (2026.8.0, new component) | Repo currently uses LD2410B/C and LD2420 (24GHz). 60GHz radar generally gives finer-grained presence/micro-motion detection and configurable zones/areas natively | Consider for a location where the 24GHz sensors give false positives/negatives (e.g. through-wall bleed) — new hardware purchase, not a drop-in firmware change |
| **Micro Wake Word: runtime wake-word add/remove** (2026.8.0) | Salon's `voice_assistant` uses wake-word detection | Switch/add wake words from HA without reflashing Salon — check if current wake-word model is still the best fit |
| **`esphome.build_flags` for IDF + PlatformIO** (2026.6.0) | Repo maintains a hand-patched `esphome-overrides/` symlink farm (PR#14119, NVS/FRAM) pinned against the pip-installed esp32 component | Could simplify future override maintenance — worth a look next time the override farm needs a rebuild, but not urgent |

### Medium Relevance ★★

| Feature | Why relevant | Notes |
|---------|-------------|-------|
| **Web server: HTTP SSE logs via native API** (2026.8.0) | Any device (debugging aid) | Live log streaming without a serial/OTA log session — nice for remote debugging Garden Gateway or Attic without physical access |
| **Mixer component: any bit depth audio** (2026.6.0) | Salon's audio pipeline (mixer + resampler) | Automatic capability improvement, no config change required unless adding a new audio source with a different bit depth |
| **YAML frontmatter for arbitrary user metadata** (2026.6.0) | Repo already tracks per-device history via comment blocks (`# Pawelo, YYYYMMDD, ...`) | Could formalize that changelog convention as structured frontmatter instead of comments — a repo-style decision, not urgent |
| **OTA: multi-key RSA signature verification** (2026.8.0) | All devices, if OTA security is ever hardened | Currently OTA uses a plain password from `secrets.yaml` — this is a stronger option if that's ever a concern, but adds real complexity |
| **Deep Sleep: `on_wake` trigger** (2026.8.0) | Not currently used anywhere in the repo | Only relevant if a future battery-powered device is added (none of the current 11 PROD devices use `deep_sleep`) |

### Lower Relevance ★

| Feature | Notes |
|---------|-------|
| **`hoermann_hcp` — Hörmann garage door protocol** (2026.8.0, new component) | **Not applicable** — confirmed 2026-09-05: Garage_Gate is a Wiśniewski operator (2009), no remote/bus protocol. Relay+endstop remains the only option. |
| **`pixoo` — Divoom Pixoo display** | Not owned hardware |
| **BMI270 / LSM6DS / QMI8658 — new IMU platforms** | No accelerometer/gyro sensor anywhere in the repo currently |
| **Network priority / multi-interface arbitration** | No device uses Ethernet + WiFi simultaneously |
| **`ufm01` ultrasonic flow meter** | Repo already uses YF-B10 pulse-counter flow sensor for water; different tech, not a replacement |

---

## New Components (full list, for reference)

From 2026.6.0–2026.8.0: Router Speaker, Motion (IMU Hub), PCM5122 (audio DAC), XDB401 (pressure), BMI270, LSM6DS, ufm01, waveshare_io_ch32v003, it8951 (e-paper controller), qmi8658, cst9220, pixoo, st7123, cst328, provisioning, image (restructured), gsl3670, ble_device_base, bk72xx_ble(+tracker), ln882h_ble(+tracker), rp2_ble_tracker, ds248x, ld6002b, modbus_client, bluetooth_connection, hoermann_hcp.

Of these, only **ds248x**, **ld6002b**, and (conditionally) **hoermann_hcp** are plausibly relevant to this repo's hardware — see ★★★/★ tables above. The rest target hardware/platforms not present here (LibreTiny BLE stacks, nRF52/RP2 wireless, touchscreens, IMUs, Modbus).

---

## Positive Fixes (No Action Required)

Automatic improvements after reflash — pulled from the 2026.6.0/7.0/8.0 changelogs and the 2026.8.1/8.2 patch notes.

| Fix | Affects | Benefit |
|-----|---------|---------|
| **`one_wire` reset busy-waiting fixed for interrupt-off + delay-wrap case** (2026.8.2) | All 6 devices with Dallas DS18B20 (`one_wire`) | More reliable temperature reads, avoids rare timing edge case |
| **ESP8266: no stale crash state reported after hardware WDT reset** (2026.8.1) | All 5 ESP8266 devices (Office, Entrance, Upstairs, Underfloor, AquariumWindow) | Cleaner crash diagnostics in HA/logs after a watchdog reset |
| **ESP32: abort/task-watchdog panics reported correctly in crash handler** (2026.8.1) | All 6 ESP32 devices | Easier root-causing if a device ever crash-loops |
| **API: loop stall fixed that could trigger the task watchdog when entity list sends block** (2026.8.1) | All devices (`api:` used everywhere) | Reduces spurious watchdog-triggered reboots |
| **BLE advertisement encode 20–33% faster, GATT bounds/UNPAIR fixes** | Any device using BLE proxy (if enabled) | Lower BLE radio overhead |
| **I2S audio DMA buffer sizing / bit-depth validation fixes** (2026.6.0) | `esp32-14_Salon.yaml` | More robust audio playback, fewer edge-case glitches |
| **Voice assistant: zero-length audio transmission prevented** (2026.6.0) | Salon voice assistant | Avoids a class of pipeline glitch |
| **ESP32 IDF DAC/LEDC adapted for ESP-IDF 6.1** | 4 devices already on esp-idf | Keeps output-related peripherals correct on the newer IDF toolchain |
| **ccache enabled by default for ESP-IDF / ESP8266 / RP2 / LibreTiny builds** | Build/compile time only | Faster local compiles when iterating on configs |

---

## Devices to Reflash — Rollout Log

Actual results, in the order flashed (least → most risky). Compile dry-run of all 11 PROD devices passed cleanly before any flashing started (only pre-existing, unrelated warnings — MQTT merge-key notice, ESP8266 flash-pin notice, cosmetic `-Waddress` compiler notes).

| Device | Status | Notes |
|--------|--------|-------|
| `esp12f-15_Upstairs` | ✅ Done 2026-09-05 | Online, I2C sensor responding, publishing normally |
| `esp12f-10_Office` | ✅ Done 2026-09-05 | Online, 3 I2C sensors (CO2/light/gas) responding, brief MQTT DNS retry then connected |
| `esp12f-25_AquariumWindow` | ✅ Done 2026-09-05 | Online, illuminance/color + temp/humidity publishing |
| `esp12f-11_Entrance_Entry` | ✅ Done 2026-09-05 | Online, BME680 + BH1750 publishing |
| `esp12f-21_Underfloor` | ✅ Done 2026-09-05 | Transient DNS failure on first attempt (pre-existing, unrelated, resolved itself); flashed fine on retry, SHT sensor + MQTT ok |
| `esp32-14_Salon` | ✅ Done 2026-09-05 | Online, BME680/lux/WiFi sensors ok. **Bootloader-too-old-for-rollback warning in boot log** — succeeded this time but see Known Issue above |
| `esp32-39_Attic` | 🔴 **Down** | OTA reported success but device never rejoined network; survived a physical power-cycle attempt with no change. Needs USB recovery — see Known Issue above |
| `esp32-06_Garden_Gateway` | ⏸️ Paused | Held back pending USB bootloader update round (shares Attic's old-bootloader risk) |
| `esp32-05_Shades_WinterGardenUpp` | ⏸️ Paused | Held back pending USB bootloader update round |
| `esp32-36_Garage_Gate` | ⏸️ Paused | Held back pending USB bootloader update round — also the highest-disruption device if it ever repeats Attic's failure (physical gate access) |
| `esp32-35_Pump_Garage` | ⏸️ Paused | Held back for USB bootloader round **and** the separate override-farm drift fix (see Known Issue above) — both must be resolved first |
| `0_DEV/esp32_dev_display.yaml` | ✅ Done 2026-09-05 | `select.state` → `.current_option()` fixed — no longer blocks compiling on ≥2026.7.0 |

**Next step**: one USB session covering `esp32-39` (recovery), `esp32-05`, `esp32-06`, `esp32-14`, `esp32-35`, `esp32-36` (bootloader update) — then resume OTA rollout for the remaining 5.

---

## Open Questions for Pawelo

- ~~**Garage_Gate hardware**: Hörmann or DIY?~~ **Answered 2026-09-05**: it's a **Wiśniewski** gate operator (2009), no remote/bus protocol — `hoermann_hcp` is not applicable, relay+endstop via `esp32-36_Garage_Gate.yaml` remains the correct approach.
- **LD6002b (60GHz radar)**: worth evaluating as a hardware upgrade anywhere the existing 24GHz LD2410/LD2420 give unreliable presence readings? This is a new purchase, not a firmware-only change.

---

## References

- [ESPHome 2026.6.0 changelog](https://esphome.io/changelog/2026.6.0/)
- [ESPHome 2026.7.0 changelog](https://esphome.io/changelog/2026.7.0/)
- [ESPHome 2026.8.0 changelog](https://esphome.io/changelog/2026.8.0/)
- [GitHub releases (2026.8.1, 2026.8.2 patch notes)](https://github.com/esphome/esphome/releases)
