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
- Version history: `Pawelo, YYYYMMDD, description`
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
