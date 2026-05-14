# ESPHome Scripts — Component Inventory

Snapshot of all ESPHome components and integrations used across this repository.
Used as a baseline for tracking what the repo uses vs. what ESPHome adds or changes over time.

> **Update this file** after every major ESPHome upgrade or significant repo restructuring.

---

## Overview

| Property | Value |
|----------|-------|
| Repo location | `~/dev/esphome_scripts` |
| Total YAML files | 310+ |
| Categories | 18 |
| Production devices | 11 |
| Development devices | 28 |
| Reusable includes | 34 |
| Sensor definitions | 80 |
| Snapshot date | 2026-05-08 |

---

## ESPHome Version

| Item | Version |
|------|---------|
| Installed in `.venv` | **2026.4.5** (latest as of 2026-05-06) |
| Last used to flash (user report) | ~2026.2 |
| Min version pins in configs | 2025.6.3 – 2025.8.0 |

Version pins are defined via `esphome_min_version` substitution variable in select configs:

| Config | Min version | Reason |
|--------|-------------|--------|
| `esp32-14_Salon.yaml` | 2025.8.0 | PSRAM execution support |
| `esp32-06_Garden_Gateway.yaml` | 2025.6.3 | baseline |
| `esp32-35_Pump_Garage.yaml` | 2025.6.3 | baseline |

---

## Platforms

| Platform | Chipset | Board types | Devices in PROD |
|----------|---------|------------|-----------------|
| **ESP8266** | ESP12E, ESP12F | esp12e, esp01_1m | 5 |
| **ESP32** | ESP32-WROOM-32, -32U, -32UE | esp32dev, esp32cam | 4 |
| **ESP32-S3** | ESP32-S3 N8R2 | esp32-s3-devkitc-1 | 1 |
| **ESP32-C3** | C3 supermini | esp32-c3-devkitm-1 | 1 |
| **LibreTuya** | BK7231N | generic-bk7231n | dev only |

### Framework

| Framework | Usage |
|-----------|-------|
| `arduino` | ESP8266 devices; some ESP32 |
| `esp-idf` | ESP32-S3 (Salon), ESP32-C3 |
| Framework version | `latest`, `recommended`, or `4.4.4` |

---

## Production Devices

These are the physically deployed devices — source of truth is `.dir_aliases` (one alias per device).
Flash using the alias, e.g. `esp10`, `esp11`, etc.

| Alias | Device | Platform | Board | Location | Function |
|-------|--------|----------|-------|----------|----------|
| `esp10` | `esp12f-10_Office.yaml` | ESP8266 | esp12e | Office | Env + CO2 + light switch |
| `esp11` | `esp12f-11_Entrance_Entry.yaml` | ESP8266 | esp12e | Entrance | Env + intercom gate |
| `esp15` | `esp12f-15_Upstairs.yaml` | ESP8266 | esp12e | Upstairs | Env monitoring |
| `esp21` | `esp12f-21_Underfloor.yaml` | ESP8266 | esp12e | Underfloor | Temp + heating |
| `esp25` | `esp12f-25_AquariumWindow.yaml` | ESP8266 | esp12e | Aquarium | Env + color |
| `esp05` | `esp32-05_Shades_WinterGardenUpp.yaml` | ESP32 | esp32dev | Winter garden | Shades + env + ePaper |
| `esp06` | `esp32-06_Garden_Gateway.yaml` | ESP32 | esp32dev | Garden | Gateway + env + relays |
| `esp14` | `esp32-14_Salon.yaml` | ESP32-S3 | esp32-s3-devkitc-1 | Salon | Hub + IR + mic + speaker |
| `esp35` | `esp32-35_Pump_Garage.yaml` | ESP32 | esp32dev (D1) | Garage | Water pump + ePaper |
| `esp36` | `esp32-36_Garage_Gate.yaml` | ESP32-C3 | c3 supermini | Garage | Gate control |
| `esp39` | `esp32-39_Attic.yaml` | ESP32 | esp32dev | Attic | Env monitoring |

---

## Components by Category

### Core / Infrastructure

| Component | Notes |
|-----------|-------|
| `api` | Home Assistant native API; used on all devices |
| `ota` | OTA firmware updates |
| `wifi` | Multiple profiles (main, extended, outside, BSSID-specific) |
| `mqtt` | MQTT broker integration; some devices use RTTTL via MQTT |
| `logger` | Configurable log level via includes; baud_rate selectable |
| `time` (sntp) | SNTP time sync; with sunrise/sunset via `sun` |
| `sun` | Solar position for automations |
| `web_server` | Local web UI; version 1/2/3 selectable |
| `captive_portal` | Fallback AP + config portal |
| `prometheus` | Metrics export (Prometheus scrape) |

### Hardware Buses

| Component | Usage in repo |
|-----------|---------------|
| `i2c` | Primary bus for most sensors (BH1750, BME680, SHT, etc.) |
| `uart` | UART-based sensors (LD2410, LD2420, YF-B10) |
| `one_wire` | DS18B20 temperature sensors |
| `spi` | ePaper displays (Waveshare) |
| `pcf8574` | GPIO expander via I2C; used in Office light switch (AVT5713) |
| `rc522` | RFID reader via SPI |
| `ir_receiver` | 38 kHz IR input (Salon) |
| `ir_transmitter` / `rtttl` | IR output + RTTTL buzzer tone sequences |

### Sensors

#### Environmental

| Sensor | Chip | Measurements |
|--------|------|-------------|
| BME680 | BME68x | Temperature, Humidity, Pressure, Gas resistance |
| BME280 | BME280 | Temperature, Humidity, Pressure |
| SHT30/41 | SHTx series | Temperature, Humidity |
| BH1750 | BH1750 | Illuminance (lux) |
| LTR390 | LTR390 | UV index + Illuminance |
| TCS3472 | TCS3472 | Illuminance + Color (RGBC) |
| SCD40 | SCD40 | CO2 + Temperature + Humidity |
| SGP30 | SGP30 | TVOC + eCO2 |
| ENS160 | ENS160 | TVOC + eCO2 |
| DS18B20 | Dallas | Temperature (waterproof probe variants) |

#### Presence / Motion

| Sensor | Protocol | Notes |
|--------|----------|-------|
| LD2410B/C | UART | 24 GHz radar, presence detection |
| LD2420 | UART | 24 GHz radar, multi-zone |
| APDS9960 | I2C | Gesture + proximity + color |
| HC-SR04 | GPIO | Ultrasonic distance |
| VL53L0X | I2C | Laser distance (ToF) |

#### Power / Energy

| Sensor | Channels | Notes |
|--------|----------|-------|
| INA226 | 1ch | DC current, voltage, power (max 30V) |
| INA3221 | 3ch | DC current, voltage, power (max 26V) |

#### Water

| Sensor | Notes |
|--------|-------|
| YF-B10 G1 | Water flow pulse counter + totalizer |

#### System / Diagnostic

| Sensor | Notes |
|--------|-------|
| `uptime` | Device uptime |
| `uptime_boot` | Boot timestamp as text sensor |
| WiFi signal | RSSI + connection state |
| Internal temp | ESP32 chip temperature (Arduino framework) |
| Firmware version | From `version` substitution variable |

#### Input

| Sensor | Notes |
|--------|-------|
| KY-023 joystick | Direction + steps |
| KY-040 rotary encoder | Direction + steps |

#### Binary sensors

30+ definitions including: door/gate state, intercom button, reed switches, relay feedback, motion, presence, RFID tag detection.

### Control / Actuators

#### Lights

| Type | Notes |
|------|-------|
| `binary` | Status LEDs (red, green, blue) |
| `rgb` (NeoPixel / WS2812) | RGB status LED on ESP32-S3 (GPIO48) |
| Light cycling scripts | Configured via include variables |

#### Switches

| Type | Notes |
|------|-------|
| Relay (HFD4-3V-S, SRD-05DC) | Mains devices; gate, lamp, solenoid |
| Buzzer (active) | Simple on/off |
| Double light switch (AVT5713) | Dual relay via PCF8574 |
| Gate control | Motor + endstop sequence |

#### Covers

| Type | Notes |
|------|-------|
| Roller blind / shade | PWM actuator with position tracking |
| Gate | Endstop-based open/close |

#### Outputs

| Type | Notes |
|------|-------|
| Passive buzzer (RTTTL) | Tone sequences via RTTTL strings |
| Door solenoid | Relay-driven lock |
| LED (status) | Binary output for status indication |

### Display / Media

| Component | Hardware | Notes |
|-----------|----------|-------|
| `epaper_spi` | Waveshare 2.90" 3-color | Pump_Garage + Shades devices |
| `lilygo_t5_47` | LILYGO T5 4.7" ePaper | Development board |
| `lcd_pcf8574` | LCD 2×16 PCF8574 I2C | Development |
| `i2s_audio` | MAX98357A | I2S amplifier (Salon) |
| `microphone` (I2S) | INMP441 | Voice assistant input (Salon) |
| `speaker` | 4Ω / 8Ω small speaker | Audio output (Salon) |
| `voice_assistant` | via HA | Wake-word detection (Salon) |
| `media_player` | via HA | Audio playback (Salon) |
| `sound_level_meter` | INMP441 (I2S) | dB measurement (development) |

### Advanced / Special

| Component | Notes |
|-----------|-------|
| `globals` | Persistent runtime variables (counters, flags) |
| `preferences` | Non-volatile storage (NVS); used for water flow totalizer |
| `packages` | Modular config composition (external_components) |
| `scripts` | Named reusable sequences |
| `select` | Dropdown entity for runtime config |
| `number` | Numeric input entity for runtime config |
| `custom API services` | `esphome.action_*` service calls from HA |
| BSEC2 (external) | BME680 advanced air quality (IAQ); requires external component |

---

## Architecture Patterns

### Include System

All device configs use variable-driven includes:

```yaml
<<: !include { file: ../includes/board_esp32.yaml, vars: { board: "esp32dev", flash_size: "4MB" } }
<<: !include { file: ../sensors/temp_hum_SHT4x.yaml, vars: { ix: "U", bus_id: "bus_b", address: "0x44" } }
```

Include categories:
- `includes/board_*.yaml` — 8 board templates (ESP8266, ESP32 variants, BK7231N)
- `includes/wifi*.yaml` — 5 WiFi profiles (main, extended, outside, BSSID-specific)
- `includes/api*.yaml`, `includes/mqtt*.yaml`, `includes/ota*.yaml` — core protocol configs
- `includes/logger.yaml` — log config with Jinja defaults (level=INFO, baud_rate=0); override per-device via `vars: {level, baud_rate}`
- `includes/web_server*.yaml` — web UI version selection

### Device Naming Convention

```
[platform]-[id]_[Location]_[Function].yaml
```

Examples: `esp12f-10_Office.yaml`, `esp32-35_Pump_Garage.yaml`

### WiFi Profiles

| Profile | Use case |
|---------|----------|
| `wifi.yaml` | Default AP |
| `wifi_main.yaml` | Primary indoor AP |
| `wifi_outside.yaml` | Outdoor perimeter |
| `wifi_multi.yaml` | Multi-network fallback |
| `wifi__bssid.yaml` | MAC-address specific (roaming prevention) |

### Flash / OTA Config

- Write interval: `5min` (default), `15min` (low-RAM devices)
- Flash sizes: 2MB, 4MB, 8MB, 16MB, 32MB
- OTA password: from `secrets.yaml`

### Versioning

Each device config tracks its own change history via comment block at the top:

```
# Pawelo, YYYYMMDD, change description
```

Firmware version is exposed as a text sensor via the `version` substitution variable.

---

## Related Files

| File | Purpose |
|------|---------|
| `Inventory.md` | Physical hardware stock (boards, sensors, components count) |
| `ESPHOME_*.md` | Version-specific upgrade impact and action items |
| `README.md` | Setup and usage instructions |
| `check_esphome_version.sh` | Script to check and upgrade ESPHome |
| `secrets.yaml` | WiFi passwords, API keys (not in git) |
| `requirements.txt` | Python dependencies (`esphome`) |
