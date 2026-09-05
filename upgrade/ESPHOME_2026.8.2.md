# ESPHome 2026.8.2 — Upgrade Impact for esphome_scripts

Covers changes from the last used version (**2026.5.3**, flashed 2026-06-14) to **2026.8.2** (latest stable, released 2026-08-31).
Use this file as a checklist when updating configs and reflashing devices.

> **Installed version:** 2026.5.3 (in `.venv`) — confirmed live 2026-09-05
> **Latest available:** 2026.8.2
> **Versions covered:** 2026.6.0–5, 2026.7.0–4, 2026.8.0–2 (minor releases researched in detail; patches from GitHub release notes)

---

## Breaking Changes

Items that **may require config changes or verification** before reflashing. Verified against the actual repo (grep), not assumed.

| Change | Affects | Action required |
|--------|---------|----------------|
| **`select` component: deprecated `.state` accessor removed** (2026.7.0) | `0_DEV/esp32_dev_display.yaml` uses `id(select_display_cycle_interval).state` (uncommented, active code, lines ~400/403/541) — will fail to compile on ≥2026.7.0 | Replace `.state` with `.state.c_str()` → already correct there, but the *pattern* itself (`.state` member access) is what's removed — replace with `.current_option()` as already done in `esp32-35_Pump_Garage.yaml` (2025-12-05 fix). This DEV file was missed by that earlier fix. |
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

## Devices to Reflash

Prioritized by risk/benefit. None of the breaking changes above require pre-flash config edits on any **PROD** file — the one required fix (`select.state`) is isolated to a **DEV** file.

| Device | Priority | Reason |
|--------|----------|--------|
| `esp32-14_Salon.yaml` | Medium | Audio pipeline fixes (I2S DMA, voice assistant zero-length fix) + light brightness-on-turn-off behavior change — verify RGB LED + TTS/voice assistant after flash |
| All 5× ESP8266 (`esp12f-10/11/15/21/25`) | Low-Medium | Crash-state reporting fix — better diagnostics only, no functional change expected |
| All 6× ESP32 (`esp32-05/06/14/35/36/39`) | Low | `one_wire` timing fix (all 6 use Dallas), crash-handler fix — general stability, no functional change expected |
| `0_DEV/esp32_dev_display.yaml` | **Fix before compiling** | Contains the removed `select.state` pattern — will fail to build on ≥2026.7.0 until fixed (see Breaking Changes) |

Suggested order: fix the DEV file first (cheap, no hardware involved) → upgrade `.venv` → compile dry-run every PROD device → flash Salon first (most complex pipeline) → flash the rest in any order.

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
