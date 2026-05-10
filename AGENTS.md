# AGENTS.md

This repository contains modular ESPHome YAML configurations for ESP devices (ESP8266, ESP32, BK7231N).

## Build and Flash Commands

```bash
# Check ESPHome version (use check_esphome_version.sh)
./check_esphome_version.sh --check-only   # Exit 10 if update available
./check_esphome_version.sh --auto          # Auto-upgrade

# Flash a device with variable substitutions
esphome -s devicename esp12f_office -s updates 30s -s room Office -s mqtt_room office run 2_PROD/esp12f-10_Office.yaml

# OTA update to specific IP (add --device flag)
esphome run 2_PROD/esp12f-10_Office.yaml --device 192.168.x.x

# Validate configuration without flashing
esphome config 2_PROD/esp12f-10_Office.yaml

# Clean build (useful after ESPHome updates)
esphome clean 2_PROD/esp12f-10_Office.yaml
```

## Device Aliases

Devices are flashed using shell aliases defined in `.dir_aliases` (loaded automatically by zsh).

| Alias | Device | Location | YAML (PROD) |
|-------|--------|----------|-------------|
| `esp05` | esp32-05 | Shades / WinterGardenUpp | `2_PROD/esp32-05_Shades_WinterGardenUpp.yaml` |
| `esp06` | esp32-06 | Garden / Gateway | `2_PROD/esp32-06_Garden_Gateway.yaml` |
| `esp10` | esp12f-10 | Office | `2_PROD/esp12f-10_Office.yaml` |
| `esp11` | esp12f-11 | Entrance / Entry | `2_PROD/esp12f-11_Entrance_Entry.yaml` |
| `esp14` | esp32-14 | Salon | `2_PROD/esp32-14_Salon.yaml` |
| `esp15` | esp12f-15 | Upstairs | `2_PROD/esp12f-15_Upstairs.yaml` |
| `esp21` | esp12f-21 | Underfloor | `2_PROD/esp12f-21_Underfloor.yaml` |
| `esp25` | esp12f-25 | AquariumWindow | `2_PROD/esp12f-25_AquariumWindow.yaml` |
| `esp35` | esp32-35 | Pump / Garage | `2_PROD/esp32-35_Pump_Garage.yaml` |
| `esp36` | esp32-36 | Garage / Gate | `2_PROD/esp32-36_Garage_Gate.yaml` |
| `esp39` | esp32-39 | Attic | `2_PROD/esp32-39_Attic.yaml` |

Each alias has a `dev` variant (e.g. `esp15dev`) that flashes the `0_DEV/` version of the same config to the same device. All aliases connect via `<devicename>.lan` hostname.

## Language

All YAML configuration files, comments (including `#*`, `#!`, `#?`, `# NOTE:`, `# WARN:`), variable names, entity names, IDs, and any other text within the configs must be written in **English only**. No Polish or other languages in the config files.

## Code Style Guidelines

### File Naming Conventions

**Device scripts**: `board_MMmm_SSss__PP.yaml`

- `board`: ESP board type (esp12f, esp32c3, esp32s3, etc.)
- `MM`: Measures (T=Temperature, H=Humidity, P=Pressure, I=Illuminance, C=CO2, etc.)
- `mm`: Manipulators (d=diode, b=buzzer, s=switch, i=IR, etc.)
- `SS`: Sensors (S=SHT3x, B=BH1750, C=SCD40, D=DS18B20, etc.)
- `ss`: Switches (r=RTTTL, b=buzzer, a=AVT5713, etc.)
- `PP`: Purpose (F=Fan, G=Gate, etc.)
- `_dev`: Development scripts with many sensors (reference implementations)

Example: `esp12f_THIb_STr.yaml` = ESP12F with Temperature/Humidity/Illuminance, buzzer, SHT3x, TCS3472, RTTTL

**Include files**: `category_specific_name.yaml` (e.g., `sensor_sht30.yaml`, `output_relay.yaml`)

- Grouped by type: `sensors/`, `outputs/`, `lights/`, `switches/`, `buttons/`, `fans/`, `interfaces/`, `includes/`

### YAML Structure

**Device scripts** follow this order:

1. Header comments with `#*` prefix
1. Version history comments with `Pawelo, YYYYMMDD,`
1. Substitutions section with default values
1. Override includes for base components (wifi, mqtt, logger, etc.)
1. Board include (`!include { file: ../includes/board_*.yaml, vars: { ... } }`)
1. Interface includes (I2C, UART, SPI, etc.)
1. Component sections (text_sensor, binary_sensor, sensor, output, light, switch, button)

**Include files**:

- Start with `---`
- Use `#` as regular comments, `#*` for sections ot key comments, `#!` for warnings or watch-outs
- Variables use `${var_name}` syntax (e.g., `${gpio}`, `${bus_id}`, `${address}`)
- Platform-specific configuration first (e.g., `platform: sht3xd`)

### Substitution Variables

**Standard variables** (default values in device scripts):

- `devicename`: Device name (default: `esp-xx`)
- `updates`: Update interval (default: `30s`)
- `room`: Friendly room name for HA/Web (default: `Room`)
- `mqtt_location`: MQTT location prefix (default: `home`)
- `mqtt_room`: MQTT room name (default: `room`)
- `room2`, `mqtt_location2`, `mqtt_room2`: Second room variants, when device expose more than 1 room
- `project_name`, `version`: Project metadata
- `devices`: List of components/devices in the device as a note to display

**Board variables** (for board_esp\*.yaml):

- `board`: PlatformIO board name (e.g., `esp12e`, `esp01_1m`)
- `board_variant`: Board variant (e.g., `12F`, `07s`, `01m`)
- `restore_from_flash`: String `"false"` or `"true"`
- `flash_write_interval`: e.g., `"5min"`

### Include Patterns

```yaml
# Simple include
<<: !include ../includes/board_esp8266.yaml

# Include with variables
<<: !include { file: ../interfaces/i2c.yaml, vars: { bus_id: "bus_a", sda: "GPIO4", scl: "GPIO0" } }

# Under component sections
sensor:
  - !include { file: ../sensors/temp_hum_SHT3x.yaml, vars: { ix: "", bus_id: "bus_a", address: "0x44" } }
```

### GPIO and Hardware Conventions

- GPIO pins specified as `GPIOXX` (e.g., `GPIO4`, `GPIO16`)
- ESP8266: Pin 9 reserved for flashing, Pin 10 use with caution (I2C SCL only)
- I2C addresses in hex format (e.g., `0x44`, `0x62`)
- I2C frequency: 50kHz (standard) or 400kHz (for compatibility with Dallas sensors)
- Variables for GPIO: `${gpio}`, `${sda}`, `${scl}`, `${address}`

### MQTT Topic Structure

- Device topic: `$devicename/sensor_id` (e.g., `esp12f-10/temperature`)
- Friendly topic: `$mqtt_location/$mqtt_room/sensor_id` (e.g., `home/office/temperature`)
- Both published via `on_value` with `!lambda` payload formatting
- State topic: `$devicename/component_id` (e.g., `$devicename/led`)

### Entity Naming

- Names use `$room` variable: `$room Temperature${ix}` (empty `${ix}` for single instance)
- IDs use lowercase with underscores: `temp${ix}`, `lux${ix}`, `relay_${ix}`, `led${ix}`
- Device class from ESPHome: `temperature`, `humidity`, `carbon_dioxide`, etc.
- Icons from MDI: `mdi:thermometer`, `mdi:water-percent`, `mdi:light-switch`, etc.

### Comment Styles

- `#*`: Key description
- `#!`: Important notes/warnings
- `#?`: Additional info/documentation
- `# NOTE:` Important usage notes
- `# WARN:` Warnings about specific behavior
- Version history: `<Author>, YYYYMMDD, description` — **mandatory on every edit**. Author = `Pawelo` for manual edits, `FLUX` for AI-agent edits. See "Persona: FLUX" → Version history convention.
- Wire diagrams: Reference `pinouts/` folder with `file://../pinouts/filename.png`

### Sensor Configuration Patterns

```yaml
platform: sht3xd
temperature:
  name: "$room Temperature${ix}"
  id: temp${ix}
  device_class: temperature
  icon: mdi:thermometer
  accuracy_decimals: 2
  state_topic: $devicename/temperature${ix}
  on_value:
    - mqtt.publish:
        topic: "$mqtt_location/$mqtt_room/temperature${ix}"
        payload: !lambda |-
          return to_string(id(temp${ix}).state);
humidity:
  name: "$room Humidity${ix}"
  id: hum${ix}
  # ... same pattern
i2c_id: ${bus_id}
address: ${address}
update_interval: $updates
```

### Logger Configuration

- Default level: `INFO` (can be overridden with `logger_level.yaml`)
- USB logging disabled by default (`baud_rate: 0`)
- Per-component log levels to reduce noise (e.g., `tcs34725: ERROR`)
- Debug component available via `interfaces/debug.yaml`

### Web Server

- Use `web_server.yaml` (version 3) for ESPHome 2.x+
- Use `web_server_basic.yaml` for version 1/2
- Sorting groups not supported in 2.x

### Secrets Management

- Copy `secrets_example.yaml` to `secrets.yaml`
- Store WiFi passwords, API keys, MQTT credentials in `secrets.yaml`
- Access with `!secret secret_name`
- Never commit `secrets.yaml` to git

### Folders Structure

- `0_DEV/`: Development configurations (working but no physical device)
- `1_UAT/`: User acceptance testing configurations (not yet deployed)
- `2_PROD/`: Production configurations (deployed devices)
- `sensors/`: Sensor configurations (binary_sensor, text_sensor, sensor)
- `outputs/`: Output components (GPIO, LED, relay, buzzer)
- `lights/`: Light components
- `switches/`: Switch components
- `buttons/`: Button components (restart, safe_mode, factory_reset)
- `interfaces/`: Hardware interfaces (I2C, UART, SPI, etc.)
- `includes/`: Base components (wifi, mqtt, ota, logger, api, time, prometheus)
- `deprecated/`: Old/non-modular configurations
- `examples/`: Example configurations and patterns

## YAML Override Mechanism

ESPHome ships a custom YAML loader at `~/dev/esphome/esphome/yaml_util.py` (function `construct_yaml_map`, lines 187-290). This loader implements the YAML 1.1 merge-key spec and behaves differently from a default PyYAML loader. Two rules are load-bearing for this repo:

1. **Plain duplicate top-level keys raise an error.** The loader (line 228-234) rejects any YAML mapping that declares the same key twice as a plain key. There are no plain duplicate top-level keys anywhere in this repo — only `<<:` merge keys.
2. **Multiple `<<: !include` entries at document root resolve first-key-wins.** When several merge-key includes appear in the same mapping, the loader (lines 266-286) processes them in source order. For each merged key:
   - if the key is already present, **keep the existing value, do not override**;
   - otherwise, add it.

Quoting the YAML 1.1 merge spec (cited verbatim in the source comment): *"Keys in mapping nodes earlier in the sequence override keys specified in later mapping nodes."*

**Practical consequence.** To override `wifi:`, `mqtt:`, `logger:`, `time:`, etc., place the override include **before** the board include. Example: in `2_PROD/esp12f-10_Office.yaml`, `<<: !include ../includes/mqtt_with_rtttl.yaml` (line 62) wins over the `<<: !include ../includes/mqtt.yaml` that lives inside `board_esp8266.yaml` (loaded at line 74) because the rtttl include came first.

This is documented behavior, not a quirk. It is stable across ESPHome versions; only an ESPHome refactor of the loader could change it (such a change would be a breaking change in the changelog).

## ESPHome Patterns Used in This Repo

- **Substitutions** — every device file opens with a `substitutions:` block (`devicename`, `room`, `mqtt_room`, `board`, `flash_size`, etc.). CLI `-s key value` overrides them at flash time. Idiomatic ESPHome, used universally.
- **`<<: !include`** for component lists — under `sensor:`, `binary_sensor:`, `output:`, `light:`, `switch:`, `button:`. Each list item is `- !include { file: ../sensors/foo.yaml, vars: { ix: "", bus_id: "bus_a", address: "0x44" } }`.
- **`packages:`** for grouped includes (modern, deterministic merge semantics) — canonical examples: `2_PROD/esp32-06_Garden_Gateway.yaml` (door cover template extended later), `2_PROD/esp32-14_Salon.yaml` (I2S media player + per-remote IR button sets).
- **`!extend`** for surgical merge into a package-loaded list — canonical example: `2_PROD/esp32-06_Garden_Gateway.yaml:213-215` extends the `door_cover` declared by a package include.
- **Secrets** — `secrets.yaml` (gitignored, see `.gitignore:4`) holds WiFi/MQTT/API credentials; refer to them with `!secret <name>`. Three layers of pre-commit secret-detection enforce no leaks.
- **Override-by-order** — multiple `<<: !include` at document root, first-key-wins (see "YAML Override Mechanism" section). Used to swap `wifi.yaml` → `wifi_main.yaml`/`wifi_outside.yaml`/etc., to inject `mqtt_with_rtttl.yaml` over the board's default `mqtt.yaml`, and to override `logger.yaml` with `logger_level.yaml`.
- **Case-sensitivity hazard** — macOS HFS+/APFS is case-insensitive; Linux/CI/Docker is not. `!include path/to/File.yaml` and `!include path/to/file.yaml` both work locally on macOS but the second fails on Linux if the on-disk filename is `File.yaml`. Always preserve case-exact match between `!include` references and on-disk filenames.

## Persona: FLUX

For any ESPHome-related task in this repo, AI agents (Cursor, Aider, Copilot, Codex, Claude Code) adopt the **FLUX** persona. The full master profile — industry expertise, repo specifics, working style, safety rules, debugging workflow, references — lives at **`.claude/agents/flux.md`**. Read it as part of mandatory reading for ESPHome work. The name belongs to the persona, not to any specific tool.

## Operational Rules (every agent, every edit)

These conventions apply to every edit in this repo regardless of which agent or persona makes it.

### Mandatory reading on entry

`AGENTS.md` (this file), `.claude/agents/flux.md` (FLUX persona), `BACKLOG.md` (cleanup state), `.yamllint`, `.pre-commit-config.yaml`, `secrets_example.yaml`.

### Version-history convention (mandatory on every YAML edit)

Every device script and include file has a version-history comment block near the top (after `#*` header comments). **On every edit to a YAML file in this repo, append a new line at the END of that block** (after the last existing entry) in the format `# <Author>, YYYYMMDD, short description of the change`. The block grows top→bottom chronologically: oldest entries at the top, newest at the bottom. Author attribution rules:

- Manual edits by Pawelo: `# Pawelo, YYYYMMDD, ...`
- Edits by an AI agent acting as the FLUX persona (FLUX itself, Cursor/Aider/Copilot/Codex/Claude Code adopting FLUX): `# FLUX, YYYYMMDD, ...`
- Use compact `YYYYMMDD` (no dashes) — that is the established convention.
- If the block doesn't exist yet in a file you're editing, create it. Do not rewrite older entries; only append new ones at the bottom. This is the change-log of record at the file level — diffing alone is not sufficient.

### BACKLOG completion convention

When you complete a `BACKLOG.md` item, **append `**Status:** ✅ done YYYY-MM-DD` to the entry body** (do not delete the entry — leave it for history). Other AI agents and the PKA KANBAN sync use this marker to count remaining work per category.

### Verify before claiming loader behavior

If asked about how YAML merges/overrides resolve, read `~/dev/esphome/esphome/yaml_util.py` directly — do not rely on PyYAML default-behavior assumptions.

### External references

- ESPHome loader source: `~/dev/esphome/esphome/yaml_util.py` (function `construct_yaml_map`, lines 187-290)
- Upgrade pipeline: `~/Documents/PKA/areas/esphome/esphome_upgrade_pipeline.md`
- ESPHome packages docs: `https://esphome.io/components/packages.html`
- YAML 1.1 merge spec: `https://yaml.org/type/merge.html`

## Repo Audit BACKLOG

Ongoing cleanup is tracked in `BACKLOG.md` at repo root — categorized inventory of strange / non-idiomatic / inconsistent patterns with severity (Cosmetic / Minor / Notable / Important) and effort (S / M / L) per item, plus a phased fix plan. Read before proposing any structural change to multiple files; many candidate edits are already enumerated there.
