# ESPHome 2026.10.0 — Upgrade Impact for esphome_scripts

Covers changes from the last installed version (**2026.8.2**) to **2026.10.0** (released 2026-10-21; 2026.9.x patches are folded in).
Use this file as a checklist when updating configs and reflashing devices.

> **Installed version:** 2026.8.2 (in `.venv`) — **not upgraded yet** (analysis only, 2026-10-23)
> **Sources:** esphome.io changelog 2026.10.0 (full page), PR descriptions #18997, #19100, #19101, #19307, #19886, upstream source at tag `2026.10.0` (`esp8266/__init__.py`, `core/config.py`, `esp32/preferences.h`).
> **Not verified by compile** — every "No action" below is a grep/source-reading result, not a build result. The ESP8266 item needs a real compile + bench run (see below).

---

## Breaking Changes

Verified against the actual repo (grep), not assumed.

| Change | Affects | Action required |
|--------|---------|----------------|
| **ESP8266: native `arduino` toolchain is now the default** (#19886; PlatformIO toolchain deprecated, removed in 2027.4.0) | All 5 ESP8266 PROD devices (esp12f-10, 11, 15, 21, 25) + ESP8266 rig esp12f-29 | **Compile + bench test required.** `framework.version: recommended` (3.1.2) and board `esp12e` are supported by the native toolchain; no custom `source:` / `platform_version` / `toolchain:` anywhere (grep). Open risk: see "`platformio_options` under native toolchain" below. |
| **`esphome: platformio_options: build_flags` deprecated under native toolchains** (removal in **2026.12.0**) | `includes/board_esp8266.yaml:36-44` — `-DVTABLES_IN_FLASH` and `-DPIO_FRAMEWORK_ARDUINO_MMU_CACHE16_IRAM32_SECHEAP_NOTSHARED` (heap/cache tuning for the Prometheus `/metrics` endpoint, 20250720) | Compile prints a deprecation warning; flags are still forwarded as plain `-D` defines. Migrate to `esphome: build_flags:` (same list) — can be done before the upgrade, `esphome->build_flags` already exists in 2026.8.2. **Whether the `PIO_FRAMEWORK_ARDUINO_MMU_*` macro still selects the 16 kB cache / 32 kB IRAM layout on the native path is unverified** — it was a PlatformIO-builder macro. Compare free heap before/after on esp12f-29 / Office. |
| **`light`: `restore_mode` → `restore_state`** (#18997) | `lights/led_rgb.yaml:28` (Salon RGB), `0_DEV/*_dev.yaml` | **No action.** `restore_mode` keeps working unchanged (only deprecated in docs). The one behavior change hits configs with `initial_state: {state: ...}` and no `restore_mode` — grep finds **no `initial_state` anywhere** in `2_PROD`, `lights`, `includes`, `0_DEV`. |
| **`remote_receiver`: RMT ring buffer sized from `receive_symbols`** (#19100) | `interfaces/ir_receiver.yaml` → active only on `esp32-14_Salon` (`rmt_symbols: 64`, no `buffer_size`) | Low risk. Ring is now 4 slots × (64×4+16 B) ≈ 1.1 kB; a NEC frame (~34 symbols) fits one slot. **Verify after flash that IR remote codes still arrive** (IR dump in log). Garden_Gateway / Garage_Gate include is commented out. |
| **`remote_receiver`: `buffer_size` = bytes on pulse-ring targets** (#19101) | ESP8266 / non-RMT targets | **Not applicable** — no `buffer_size` set anywhere (grep); `ir_receiver__arduino.yaml` is not included by any active PROD file. |
| **`speaker` media player: volume and mute independent; `codec_support_enabled` removed** (#19307, #18412, #19074) | `esp32-14_Salon` (`i2s/set_i2s_media_player.yaml`, MAX98357A) | `codec_support_enabled` — not used (grep). Behavior: volume 0 no longer reports "muted", changing volume while muted keeps mute, boot no longer forces mute for saved volume 0. No `on_mute`/`on_unmute` automations in the repo. **Check the media player in HA after flash** (volume slider + mute button). |
| **`epaper_spi`: reTerminal Sticky / SSD1677 changes** (#19213) | `esp32-05`, `esp32-35` use `epaper_spi` with model `weact-2.9in-3c` | **Not applicable** — breaking change is limited to reTerminal Sticky (SSD1677). |
| **`serial_proxy`, `sendspin` switch, `hoermann_hcp`, `usb_host`, `host` platform, `teleinfo`** | — | **Not applicable** — none used (grep). `host` is only built if someone runs it locally. |
| **ESP32: mbedTLS trimmed to client-only defaults** (#19088) | All ESP32 PROD (MQTT client, API, OTA) | Low risk — repo only uses TLS as a client. No ESP32 runs an HTTPS server. Watch MQTT/OTA reconnect in the first boot log. |
| **ESP32: recommended Arduino bumped to 3.3.12 / PlatformIO 6.2.0** (#19417) | `esp32-36_Garage_Gate`, `esp32-35_Pump_Garage` (Arduino framework, `framework_version: recommended`) | Recompile sweep covers it. esp32-35 stays pinned (see below). |

### `platformio_options` under native toolchain (ESP8266) — details

From upstream `core/config.py` (`_add_platformio_options`) at 2026.10.0: under a native toolchain `build_flags` is deprecated-but-forwarded (`cg.add_build_flag`), `build_unflags` / `lib_deps` / `lib_ignore` are translated, and only `board_build.f_cpu`, `board_build.ldscript`, `board_upload.maximum_size` are honored from the rest; everything else logs `... is ignored when building with the native 'arduino' toolchain`. This repo sets only `build_flags`, so nothing is silently dropped — but the *effect* of the MMU macro on the memory map is the thing to measure.

Fallback if the native toolchain behaves worse (heap, crashes): add `toolchain: platformio` under `esp8266:` in `includes/board_esp8266.yaml` (works until 2027.4.0, prints a deprecation warning).

### Override farm (`esphome-overrides/`, PR#14119 NVM/FRAM) — expected drift

Checked ahead of time against upstream `2026.10.0` (snapshot diff, per `feedback_refresh_sh_check_snapshots`):

- `.preferences.h.upstream` and `.preference_backend.h.upstream` **differ from 2026.10.0**: upstream added RTC-backed preference storage (`USE_ESP32_RTC_PREFERENCES`, `rtc_offset`, `in_flash`, `load_from_key`). `refresh.sh` will report `⚠ CHANGED` → a manual rebase of the two patched headers is required before any FRAM build compiles.
- Farm is also missing two new sibling files (`atexit_stubs.cpp`, `vasprintf_stubs.cpp`) — `refresh.sh` re-symlinks them.
- The snapshot already differs from pip 2026.8.2, i.e. the drift Pawelo declined to fix on 2026-10-08 (`esp32-35` pinned on 2026.5.3). **2026.10.0 does not change that decision**: FRAM/NVM is not in the changelog and PR#14119 is closed upstream.
- Consequence: only `esp32-35_Pump_Garage` and the FRAM rig `esp32-32` depend on the farm. Everything else upgrades normally. Keep `esp32-35` on 2026.5.3.

---

## New Features Worth Exploring

| Feature | Rating | Why |
|---------|--------|-----|
| **Native ESP8266 toolchain** — fresh build 17.8 s → 9.2 s, warm ccache 7.6 s → 2.8 s (#19886 numbers); runs natively on Apple Silicon (no Rosetta) | ★★★ | Faster 5-device sweep; removes the Rosetta dependency on pMacM5. |
| **Compressed OTA uploads** (#19037, ESP8266/ESP32/LibreTiny) | ★★ | Faster OTA on weak WiFi (Pump, Attic). Automatic, no config. |
| **`esp32: skip-bootloader` for OTA-only builds** (#19925) | ★★ | Handy in the bootloader-refresh procedure (esp32-05/06 lessons). |
| **Outgoing API connections / HA onboarding wizard** (#18919, #19966) | ★ | Not needed; devices keep the current HA link. |
| **`suspend_loop` / `loop_interval`** (#18136) | ★ | Possible power/CPU savings later; nothing to do now. |
| **`i2s_audio` software volume ramping** (#19302) | ★ | Less clicking on Salon speaker. |
| **FRAM / NVM component** | — | **Not in this release.** Do not wait for it in 2026.10.x. |

## Positive Fixes

- ESP8266: UART software-serial RX ISR no longer blocks for a whole byte (#18519); `spi` writes avoid a heap copy (#19265); log strings kept in flash (#19577); ArduinoJson float tables in flash (#20416).
- ESP8266 `wifi`: failed attempt no longer poisons the next one (#20183) — relevant to flaky-WiFi devices.
- `remote_receiver` wakes the main loop on RMT frame (#19102).
- `esp32`: NVS cache in PSRAM when guaranteed (#19378); UART flushed before sleep on IDF 6 (#18975).
- Many `register_apply_action` / user-provided-constructor refactors — flash/RAM savings, no config impact.

---

## Pre-Flight Checks

```bash
cd ~/dev/esphome_scripts
grep -rn "initial_state" --include='*.yaml' 2_PROD lights includes 0_DEV        # expect: none
grep -rn "buffer_size" --include='*.yaml' 2_PROD interfaces includes 0_DEV      # expect: none
grep -rn "codec_support_enabled" --include='*.yaml' .                           # expect: none
grep -rn "toolchain:\|platform_version\|source:" --include='*.yaml' 2_PROD includes | grep -v "^\S*:[0-9]*:\s*#"
grep -n "platformio_options" -A3 includes/board_esp8266.yaml                    # the deprecated build_flags
```

## Devices to Reflash

Order follows `feedback_flash_order_simple_first`: rigs first, simplest device within a chip family first, Office (most sensors) last.

| Priority | Device | Platform | Reason / what to verify |
|----------|--------|----------|--------------------------|
| 0 | **esp12f-29 rig** | ESP8266 | **Mandatory smoke test** — first real native-toolchain build. Compare free heap with 2026.8.2 (MMU flags question). |
| 0 | **esp32-32 rig** | ESP32-C3 | Mandatory smoke test (note: override farm needs rebase first if the FRAM config is flashed; plain `esp32c3_dev.yaml` does not use it). |
| 1 | esp12f-15 Upstairs | ESP8266 | Simplest ESP8266 — validates native toolchain on a PROD node. |
| 2 | esp12f-25 AquariumWindow, esp12f-21 Underfloor, esp12f-11 Entrance_Entry | ESP8266 | Same toolchain, more peripherals. |
| 3 | esp12f-10 Office | ESP8266 | Most sensor-heavy, Prometheus `/metrics` heap sensitivity — last. |
| 4 | esp32-39 Attic, esp32-06 Garden_Gateway, esp32-05 Shades | ESP32 | mbedTLS trim; watch MQTT/OTA reconnect. |
| 5 | esp32-36 Garage_Gate | ESP32-C3 (Arduino) | Arduino 3.3.12. |
| 6 | esp32-14 Salon | ESP32-S3 | IR receiver ring + media player volume/mute behavior — verify in HA. |
| — | **esp32-35 Pump_Garage** | ESP32 | **Stay on 2026.5.3** (override farm drift, FRAM not upstream). |

MQTT `esp` account migration (anonymous list from Larry, 2026-10-19) rides along with each flash per `feedback_mqtt_esp_creds_with_upgrade`: esp12f-10/11/15/21/25, esp32-05/06/14/32/36 (esp32-39 status unknown).

## Upgrade steps still ahead (SOP)

1. `pip install -U esphome` → `bash esphome-overrides/refresh.sh` (expect `⚠ CHANGED`, see above).
2. Update `COMPONENTS.md` (installed version, snapshot date, mention native ESP8266 toolchain).
3. Compile sweep: one ESP8266 PROD (`esp12f-10`), one ESP32 (`esp32-39`), ESP32-S3 (`esp32-14`), ESP32-C3 (`esp32-36`); then `find 0_DEV -name "*.yaml"` sweep.
4. Rig smoke tests → PROD flash in the order above.
