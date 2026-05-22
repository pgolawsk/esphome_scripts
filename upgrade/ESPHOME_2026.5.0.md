# ESPHome 2026.5.0 — Upgrade Impact for esphome_scripts

Covers changes from the last used version (**2026.4.5**) to **2026.5.0** (released 2026-05).
Use this file as a checklist when updating configs and reflashing devices.

> **Installed version:** 2026.4.5 (in `.venv`) — upgrade to 2026.5.0
> **Previous version used:** 2026.4.5
> **Versions covered:** 2026.5.0

---

## Breaking Changes

Items that **may require config changes** before reflashing.

| Change | Affects | Action required |
|--------|---------|----------------|
| **WAV codec now requires explicit declaration** | `esp32-14_Salon.yaml` (media player, HA TTS) | Test TTS after flash. If TTS breaks, add `audio: codecs: wav:` block to the Salon config or to `i2s/set_i2s_media_player.yaml` |
| **API connections: max 5 (was 8) on ESP32/BK72XX** | All 6 ESP32 PROD devices | No config change — but be aware if HA + Dashboard + other API clients connect simultaneously |
| **`speaker: codec_support_enabled` deprecated** | Not used in this repo | No action. If voice assistant pipeline is re-enabled in Salon, use `format:` in pipeline instead |
| **OTA: single `platform: esphome` entry required** | `includes/ota.yaml` | Already correct (web_server entry is commented out). No action needed |
| **`throttle_average` filter: `time_period` capped at 24h** | Any sensor using `throttle_average` | `grep -rn "throttle_average" --include="*.yaml" . \| grep -v ".esphome"` — check if any sensor uses >24h period |

### Quick verification commands

```bash
# Run from repo root before reflashing
# WAV / audio codec (check Salon media player is active and has no explicit codec declared)
grep -rn "codec_support_enabled" --include="*.yaml" . | grep -v ".esphome"
grep -rn "throttle_average" --include="*.yaml" . | grep -v ".esphome"
# Verify OTA config is still single-entry
grep -A5 "^ota:" includes/ota.yaml
```

---

## New Features Worth Exploring

Rated by relevance to this repo's architecture.

### High Relevance ★★★

| Feature | Why relevant | How to use |
|---------|-------------|-----------|
| **Main loop now runs at configured cadence** (not silently accelerated) | Fixes timing accuracy for gate motor (esp32-36), pump timer (esp32-35), and any device relying on scheduled intervals. Also fixes watchdog feed regression that was 1000× too aggressive | Automatic after reflash — verify gate open/close timing on esp32-36 |
| **Native ESP-IDF toolchain** (`toolchain: esp-idf`) | Salon already uses `framework: esp-idf`. New native toolchain eliminates PlatformIO overhead; supports ESP-IDF v6.0.1 | Add `toolchain: esp-idf` under `esp32: framework:` in `board_esp32s3.yaml` or Salon directly. Optional — default still works |
| **Audio stack: microMP3 / microFLAC / microWAV streaming codecs** | Salon has full media player pipeline (speaker + mixer + resampler). New codecs enable MP3/FLAC streaming in addition to WAV | Add `audio: codecs: mp3:` (and/or `flac:`) to Salon config to enable streaming those formats from HA |
| **`audio_http` media source** | Salon media player can now play arbitrary HTTP URLs directly from ESPHome YAML without HA automation | Add `media_source: audio_http` and use `media_player.play_media` with URL in ESPHome automations |
| **`esphome upload --bootloader`** | 5 PROD devices flagged as "bootloader too old" in previous cycle (esp32-05, esp32-06, esp32-35, esp32-36, esp32-39). 2026.5.0 adds explicit bootloader update command | `esphome upload --bootloader 2_PROD/<device>.yaml` — requires USB connection; attempt during next physical access to each device |

### Medium Relevance ★★

| Feature | Why relevant | Notes |
|---------|-------------|-------|
| **OTA: partition table updates + factory partition fallback** | All ESP32 devices can now recover from soft-brick via factory partition | Automatic once reflashed with 2026.5.0; no config change |
| **OTA: better error messages** | All devices | Easier debugging when OTA fails |
| **RingBuffer as first-class component** | Salon audio pipeline uses ring buffers internally via mixer/resampler stack | Automatic improvement to audio buffering stability |
| **sendspin multi-room audio** | If adding a second audio device (e.g. speaker in another room) | New `sendspin:` component for synchronized audio group playback |
| **`radio_frequency` entity type + `ir_rf_proxy`** | Gate (esp32-36) could expose RF commands as entity type | New `radio_frequency:` top-level; `ir_rf_proxy` platform — consider for garage RF remote if RF receiver added |

### Lower Relevance ★

| Feature | Notes |
|---------|-------|
| **Zigbee on ESP32-H2/C6** | esp32-36 is C3 — not supported. Relevant only if a new H2 or C6 device is added |
| **LVGL: flexible grid, touch coordinates in lambdas** | esp32-05 uses ePaper display but not LVGL — watch for future display projects |
| **nRF52 + Zephyr platform support** | Not used in this repo |
| **ESPHome Device Builder (Beta web app)** | Replaces the old dashboard; no config changes needed |

---

## Positive Fixes (No Action Required)

These changes improve stability and performance automatically after reflash.

| Fix | Affects | Benefit |
|-----|---------|---------|
| **ESP8266 `millis()` 2.7× faster** | All 5 ESP8266 devices (Office, Entrance, Upstairs, Underfloor, AquariumWindow) | Lower scheduling overhead; faster sensor polling loops |
| **ESP32 `millis()` → `xTaskGetTickCount()`** | All 6 ESP32 devices | More accurate timing, lower overhead |
| **Watchdog feed regression fixed (was 1000× too aggressive)** | All devices | Correct watchdog behavior; reduces spurious resets risk |
| **BLE advertisement encode 20–33% faster** | Any device using BLE proxy | Reduced BLE radio overhead |
| **I2S audio volume calculation 45% cheaper** | `esp32-14_Salon.yaml` | Lower CPU usage during media playback |
| **`safe_mode` + `rtttl` callback storage gated** | Office (RTTTL buzzer), all devices with safe_mode | Smaller firmware flash footprint per device |
| **API socket fast-path tightened** | All devices with `api:` | Faster HA API response |
| **Light/callback hot paths inlined** | Salon RGB LED, all light components | Lower latency on light state changes |
| **FloatOutput power scaling gated** | Any device with LED PWM outputs | −12B flash per output instance |
| **Scheduler pool: intrusive freelist** | All devices | Reduced heap fragmentation, lower memory usage |
| **Parallel external_files downloads (8 workers)** | Build time for devices with external components (Salon, Pump_Garage) | Faster compile on cold cache |

---

## Devices to Reflash

Prioritized by risk of breaking change or benefit of new features.

| Device | Priority | Reason |
|--------|----------|--------|
| `esp32-14_Salon.yaml` | **Done** 2026-05-22 | Audio pipeline: verify WAV/TTS after flash. Main loop timing fix. I2S audio stack improvements. Compile first with `esphome compile` |
| `esp32-36_Garage_Gate.yaml` | **Done** 2026-05-22 | Main loop cadence fix directly affects gate motor timing. Verify open/close sequence unchanged after flash. (⚠️ bootloader old — OTA only; USB when physically accessible) |
| `esp32-35_Pump_Garage.yaml` | **Done** 2026-05-22 | Flashed from migrated `0_DEV` (nvm/fram_i2c + epaper_spi); since promoted to `2_PROD`. Stable 64s, no boot-loop. (⚠️ bootloader old) |
| `esp12f-10_Office.yaml` | Done 2026-05-22 | millis() 2.7× speedup; RTTTL flash saving |
| `esp12f-11_Entrance_Entry.yaml` | Done 2026-05-22 | millis() 2.7× speedup |
| `esp12f-15_Upstairs.yaml` | Done 2026-05-22 | millis() 2.7× speedup |
| `esp12f-21_Underfloor.yaml` | Done 2026-05-22 | millis() 2.7× speedup |
| `esp12f-25_AquariumWindow.yaml` | Done 2026-05-22 | millis() 2.7× speedup |
| `esp32-05_Shades_WinterGardenUpp.yaml` | Done 2026-05-22 | Main loop + general ESP32 improvements. (⚠️ bootloader old) |
| `esp32-06_Garden_Gateway.yaml` | Done 2026-05-22 | Main loop + general ESP32 improvements. (⚠️ bootloader old) |
| `esp32-39_Attic.yaml` | Done 2026-05-22 | Env only — low risk. (⚠️ bootloader old) |

---

## Carryover to Next Upgrade Cycle

- **Bootloader update for 5 devices** (esp32-05, esp32-06, esp32-35, esp32-36, esp32-39). 2026.5.0 adds `esphome upload --bootloader` — attempt during next physical USB access to each device. Resolves the OTA rollback + SRAM1 IRAM limitation noted since 2026.4.5.
- **WAV codec declaration** — if Salon TTS breaks after upgrade, add `audio: codecs: wav:` to `i2s/set_i2s_media_player.yaml` and reflash.
- **Native ESP-IDF toolchain** (`toolchain: esp-idf`) for Salon — low urgency, consider for next Salon config change.

---

## References

- [ESPHome 2026.5.0 changelog](https://esphome.io/changelog/2026.5.0/)
- [GitHub releases](https://github.com/esphome/esphome/releases)
