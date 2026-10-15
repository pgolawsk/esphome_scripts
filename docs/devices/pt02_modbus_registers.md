# GZAIR PT02 air-quality monitor — Modbus RTU register map

Device: GZAIR PT02 "6-in-1 Smart Air Quality Monitor" (Guangdong Yiru Intelligent Technology), bought on AliExpress. It connects to Tuya / Smart Life over Wi-Fi and shows as "PT02" in the app. The rear panel has an RS485 "Modbus 485" port and alarm relays. The manufacturer publishes no Modbus documentation. This map was built empirically.

- **Status:** verified 2026-10-16. The map is complete except for HR0, IR4 and IR7–9.
- **Method:** registers were read with FC03/FC04 only. Reads were compared with the device display. Then single settings were changed in the Tuya app and registers were diffed before/after. **Nothing was ever written over Modbus.**
- **Knowledge base:** PKA `areas/esphome/pt02_air_quality_sensor.md`.

## Connection

| Parameter | Value |
|-----------|-------|
| Protocol | Modbus RTU over RS485 |
| Slave address | 100 (0x64) |
| Serial | 9600 baud, 8N1 |
| Frame gap | ≥150 ms between requests. Back-to-back requests are silently dropped. |
| Response timeout | ~1 s |
| Functions | FC04 input registers 0–9, FC03 holding registers 0–17. Higher addresses → exception 2. |

Wiring gotcha: if the bus is totally silent on every baud/parity, swap A/B. That was the fix on 2026-10-15.

## Input registers (FC04) — measurements

| Reg | Measurement | Raw → value | Verified by |
|-----|-------------|-------------|-------------|
| 0 | CO2 | ppm | 591 vs display 588 |
| 1 | TVOC | ×0.01 mg/m³ | 3 vs display 0.02 |
| 2 | PM1.0 | µg/m³ | live: 4 = display 4 |
| 3 | PM2.5 | µg/m³ | live: 4→5 tracked display |
| 4 | **unknown**, likely PM10 (not on display) | µg/m³? | always ≥ PM2.5 so far |
| 5 | temperature | ×0.1 °C, **always °C** even when the display is set to °F | 226 vs display 22 |
| 6 | relative humidity | ×0.1 % | 443 vs display 44 |
| 7–9 | **unknown** | — | always 0 |

## Holding registers (FC03) — configuration

> **Do not write any of these (FC06/FC16).** They drive mains-voltage alarm relays, and HR0 is unknown, possibly comm config (address/baud). A bad write could make the device unreachable. Change settings in the Tuya app instead.

| Reg | Setting (Tuya app name) | Raw → value | Verified by |
|-----|-------------------------|-------------|-------------|
| 0 | **unknown**, constant 0xF001 (61441) | — | never changed |
| 1 / 2 | CO2 alarm upper / lower | ppm | app change 1500→1400 |
| 3 / 4 | TVOC alarm upper / lower | ×0.01 mg/m³ | app change 8.1→8.0 (810→800) |
| 5 / 6 | humidity alarm upper / lower | ×0.1 % | matched app values |
| 7 / 8 | PM2.5 alarm upper / lower | µg/m³ | matched app values |
| 9 / 10 | PM1.0 alarm upper / lower | µg/m³ | matched app values |
| 11 / 12 | temperature alarm upper / lower | ×0.1 °C | matched app values |
| 13 | alarm time | seconds (app max 60) | matched app value |
| 14 | control open delay | seconds | 80 = app "1 min 20 s" |
| 15 | control close delay | seconds | 20 = app "20 s" |
| 16 | backlight | 0 = closed, 1 = Level 1, 2 = Level 2 | toggled in app |
| 17 | bit field, see below | — | toggled in app |

HR17 bits:

| Bit | Meaning |
|-----|---------|
| 0 | Mute: 1 = alarm sound off, 0 = sound on |
| 1 | Display unit: 1 = °F, 0 = °C |

Observed on 2026-10-16: switching the display to °F also changed the backlight from Level 2 to Level 1.

Values recorded on 2026-10-16 (the owner had already changed CO2 upper and TVOC upper):

```
HR: 61441 1400 1000 800 300 400 300 75 35 45 25 380 310 10 80 20 1 1
```

The factory values for CO2 upper and TVOC upper were 1500 ppm and 8.10 mg/m³ (raw 810).

## Read-only test script (macOS, pyserial)

```python
import serial, struct, time
def crc(d):
    c = 0xFFFF
    for b in d:
        c ^= b
        for _ in range(8):
            c = (c >> 1) ^ 0xA001 if c & 1 else c >> 1
    return struct.pack('<H', c)
s = serial.Serial('/dev/cu.usbserial-<SERIAL>', 9600, timeout=1.0)
def q(fn, reg, n, addr=100):
    f = bytes([addr, fn]) + struct.pack('>HH', reg, n); f += crc(f)
    s.reset_input_buffer(); s.write(f); r = s.read(5 + 2 * n); time.sleep(0.15)
    if len(r) >= 5 and crc(r[:-2]) == r[-2:]:
        return f'ex{r[2]}' if r[1] & 0x80 else list(struct.unpack(f'>{r[2]//2}H', r[3:-2]))
    return None
print('input  ', q(4, 0, 10))
print('holding', q(3, 0, 18))
```

From Claude Code, run this with the sandbox disabled, because the serial device ioctl is blocked inside it. The generic discovery runbook is `pawelo_scripts/mac/pMac_modbus_rtu_discovery.sh`.

## ESPHome notes

- Read FC04 registers 0–6 only (`register_type: read`), with `update_interval` ≥ 30 s.
- Unverified: ESPHome docs reportedly mark `modbus_controller: command_throttle` as deprecated and put the frame gap on `modbus: turnaround_time`. Check this before writing the config.
- Do not add `number` / `switch` / `select` entities that write HR registers.

## History

- 2022-11: first attempts, see `pt02_rs485_setup.sh` (never connected: wrong address/baud tried; A/B wiring is a guess, not verified).
- 2026-10-15: link established at slave 100 / 9600 8N1, raw register dump.
- 2026-10-16: full register map built by display comparison and Tuya app toggling.
