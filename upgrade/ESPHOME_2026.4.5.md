# ESPHome 2026.4.5 — Upgrade Impact for esphome_scripts

Covers changes from the last used version (**~2026.2**) to **2026.4.5** (released 2026-05-06).
Use this file as a checklist when updating configs and reflashing devices.

> **Installed version:** 2026.4.5 (in `.venv`)
> **Previous version used:** ~2026.2
> **Versions covered:** 2026.3.0, 2026.4.0, 2026.4.x patch releases

---

## Breaking Changes

Items that **may require config changes** before reflashing.

| Change | Affects | Action required |
|--------|---------|----------------|
| **ESP32 default CPU frequency: 160→240 MHz** | All 6 ESP32/S3/C3 PROD devices | Mains-powered = OK (no change needed). Battery-powered: add `cpu_frequency: 160MHZ` under `esp32:` |
| **C++ Trigger API: `trigger_id` in lambdas removed** | Any config with C++ lambdas | `grep -r "trigger_id" .` — if found, migrate to `script:` based approach |
| **LVGL v9 upgrade — breaking config changes** | Configs using LVGL (displays) | Check `esp32-05_Shades_WinterGardenUpp.yaml` (ePaper with display) — if using LVGL, test display rendering |
| **UART: `FlushResult` enum renamed to `UARTFlushResult`** | Configs with UART lambdas | `grep -r "FlushResult" .` — rename in any lambda that uses it |
| **Sensor `.raw_state` deprecated → use `get_raw_state()`** | Any lambda reading raw sensor value | `grep -r "\.raw_state" .` — replace with `get_raw_state()` calls |

### Quick verification commands

```bash
# Run from repo root to find items needing attention
grep -rn "trigger_id" --include="*.yaml" . | grep -v ".esphome"
grep -rn "FlushResult" --include="*.yaml" . | grep -v ".esphome"
grep -rn "\.raw_state" --include="*.yaml" . | grep -v ".esphome"
```

---

## New Features Worth Exploring

Rated by relevance to this repo's architecture.

### High Relevance ★★★

| Feature | Version | Why relevant | How to use |
|---------|---------|-------------|-----------|
| **GPIO expander interrupt support** | 2026.4 | Repo uses PCF8574 in Office (AVT5713 switch board). Interrupt-driven mode eliminates I2C polling → up to 99.7% reduction in idle bus traffic | Add `interrupt_pin:` to PCF8574 config when GPIO pin is available |
| **Jinja expressions in `!include` filenames** | 2026.4 | Repo uses heavy `!include` templating with vars. Jinja in filenames allows dynamic include paths | `<<: !include { file: "../{{ platform }}_board.yaml" }` — simplifies multi-platform configs |
| **Client-side logging (46× faster sensor publishing)** | 2026.4 | Fleet of 38+ devices; log formatting moved from device to HA client — reduces CPU/memory load on device | Automatic; no config change needed. Verify logger is enabled |

### Medium Relevance ★★

| Feature | Version | Why relevant | Notes |
|---------|---------|-------------|-------|
| **Socket polling on ESP32 (99× faster)** | 2026.3 | All ESP32 PROD devices benefit — faster API response, lower latency | Automatic; no config change |
| **Light gamma correction (8-10× faster)** | 2026.3 | RGB LEDs in Salon (WS2812 on GPIO48) | Automatic |
| **API Protobuf encoding (6-12× faster)** | 2026.3 | All devices with `api:` component | Automatic |
| **Dew point calculator component** | 2026.3 | Devices with temp+humidity sensors in all rooms | Add as a template sensor derived from existing SHT/BME readings |
| **Serial proxy (remote UART access)** | 2026.3 | Useful for debugging LD2410/LD2420 radar sensors without serial cable | Add `serial_proxy:` component for UART debugging sessions |
| **Read-only bridge: number/text → sensor** | 2026.4 | View config numbers as sensors in HA dashboards | Useful for exposing threshold values |

### Lower Relevance ★

| Feature | Version | Notes |
|---------|---------|-------|
| **Ethernet support: W5500, W6100, ENC28J60 on ESP32** | 2026.4 | Could be interesting for Garden Gateway if ethernet cable is run |
| **New sensors: SEN6x (multi-channel env)** | 2026.3 | Up to 7 measurements in one sensor — consider for next build |
| **New sensors: HDC2080, SPA06-003** | 2026.4 | SPA06-003 = pressure+temp; HDC2080 = temp+humidity — alternatives to current chips |
| **RP2040/RP2350 first-class support** | 2026.3 | Not used in this repo currently |
| **nRF52 OTA via BLE** | 2026.3 | Not used in this repo |

---

## Positive Fixes (No Action Required)

These changes improve stability and reliability automatically — no config changes needed.

| Fix | Affects | Benefit |
|-----|---------|---------|
| **ESP8266 crash handler parity** | All 5 ESP8266 devices | Post-mortem crash diagnostics now sent via WiFi without serial cable — easier remote debugging |
| **LWIP use-after-free bug fixed** | ESP8266 + RP2040 | Eliminated heap corruption crashes under high network load. Office, Entrance, Upstairs, Aquarium, Underfloor all benefit |
| **LibreTuya BK72xx loop stall reduced: 110ms → 14ms** | Dev BK7231N device | Faster response in development |

---

## Devices to Reflash

Prioritized by risk of breaking change or benefit of new features.

| Device | Priority | Reason |
|--------|----------|--------|
| `esp12f-11_Entrance_Entry.yaml` | High | ESP8266 LWIP fix + crash handler |
| `esp12f-10_Office.yaml` | High | ESP8266 LWIP fix + PCF8574 interrupt opportunity |
| `esp12f-15_Upstairs.yaml` | Medium | ESP8266 LWIP fix |
| `esp12f-21_Underfloor.yaml` | Medium | ESP8266 LWIP fix |
| `esp12f-25_AquariumWindow.yaml` | Medium | ESP8266 LWIP fix |
| `esp32-14_Salon.yaml` | Medium | Verify PSRAM + BSEC2 still work; RGB LED gamma fix |
| `esp32-05_Shades_WinterGardenUpp.yaml` | Medium | Check ePaper display if LVGL used |
| `esp32-06_Garden_Gateway.yaml` | Low | Socket polling benefit |
| `esp32-35_Pump_Garage.yaml` | Low | ePaper + flow counter — stable config |
| `esp32-36_Garage_Gate.yaml` | Low | Gate motor — verify relay behavior unchanged |
| `esp32-39_Attic.yaml` | Low | Env only — low risk |

---

## Upgrade Procedure

```bash
# 1. Activate venv
cd ~/dev/esphome_scripts
source .venv/bin/activate

# 2. Verify version
esphome version

# 3. Run breaking change grep before reflashing
grep -rn "trigger_id\|FlushResult\|\.raw_state" --include="*.yaml" . | grep -v ".esphome"

# 4. Compile & flash one device (dry run first)
esphome compile 2_PROD/esp12f-11_Entrance_Entry.yaml
esphome run 2_PROD/esp12f-11_Entrance_Entry.yaml --device 192.168.x.x
```

---

## References

- [ESPHome 2026.4.0 changelog](https://esphome.io/changelog/2026.4.0/)
- [ESPHome 2026.3.0 changelog](https://esphome.io/changelog/2026.3.0/)
- [GitHub releases](https://github.com/esphome/esphome/releases)
