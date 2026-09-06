# ESPHome 2026.8.2 — Upgrade Impact for esphome_scripts

Covers changes from the last used version (**2026.5.3**, flashed 2026-06-14) to **2026.8.2** (latest stable, released 2026-08-31).
Use this file as a checklist when updating configs and reflashing devices.

> **Installed version:** 2026.8.2 (in `.venv`) — upgraded 2026-09-05
> **Versions covered:** 2026.6.0–5, 2026.7.0–4, 2026.8.0–2 (minor releases researched in detail; patches from GitHub release notes)
> **Rollout status (2026-09-06, updated later same day):** 7 of 11 PROD devices flashed and verified — 5 on 2026-09-05, `esp32-14_Salon` recovered via USB from M1 earlier on 2026-09-06, plus `esp32-36_Garage_Gate` bootloader-updated via full USB flash from pMacM5 in the evening. **1 device still down** (`esp32-39_Attic`, needs USB recovery, deferred — dismount from attic required). **3 devices paused** pending USB bootloader update (`esp32-05`, `esp32-06`, `esp32-35`). **pMacM5 USB flashing is FIXED** (disabled WCH driver extension — enabled it; see resolved Known Issue below). M1 no longer required.

---

## Breaking Changes

Items that **may require config changes or verification** before reflashing. Verified against the actual repo (grep), not assumed.

| Change | Affects | Action required |
|--------|---------|----------------|
| **`select` component: deprecated `.state` accessor removed** (2026.7.0) | `0_DEV/esp32_dev_display.yaml` used `id(select_display_cycle_interval).state` (6 occurrences) — would have failed to compile on ≥2026.7.0 | **Fixed 2026-09-05** — replaced with `.current_option()`, same pattern already applied to `esp32-35_Pump_Garage.yaml` (2025-12-05 fix) |
| **LWIP socket requirements grew — `CONFIG_LWIP_MAX_SOCKETS: 16` no longer enough** | `includes/board_esp32s3.yaml` (Salon, esp32s3_dev, esp32s3supermini_dev) — compile warning: config needs 18 sockets (12 TCP + 3 UDP + 3 TCP_LISTEN) | **Fixed 2026-09-06** — bumped to 20 (`MAX_ACTIVE_TCP` 16→18). Real-world symptom before the fix: Salon's MQTT client failed to connect with repeated `esp-tls: delayed connect error: Software caused connection abort` (socket exhaustion, not a broker/network problem) — confirmed resolved via OTA reflash |
| **`esp32_rmt_led_strip`: `rgb_order` deprecated, use `channel_colors`** | `lights/led_rgb.yaml` (Salon + other RGB LED consumers) and `0_DEV/esp32-33_s3_VA_full.yaml` — removed in 2027.3.0 | **Fixed 2026-09-06** — renamed `rgb_order: GRB` → `channel_colors: GRB` in both files, same value. Verified via `esphome config` — no errors. Surfaced by the M1 recovery flash log for Salon. |
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

**A 6th device shared this risk**: `esp32-14_Salon.yaml` printed on successful boot (2026-09-05):
```
[W][app:193]: Bootloader too old for OTA rollback. Flash via USB once to update the bootloader
```
Salon's OTA happened to succeed that time, but it carried the identical exposure for any *future* OTA.

**Resolved for Salon, 2026-09-06** — verified via a clean OTA restart (`esphome run`, reset reason `Reboot request from esphome.ota`) and a full fresh boot-log capture from `app:151` onward: the `Bootloader too old` warning no longer appears. The full `esphome run` used to recover Salon via USB from M1 (see Known Issue below) wrote a fresh bootloader from offset 0x0 as part of that flash, which incidentally fixed this too — not something I'd verified until asked directly; the impact-file note below had been carried over stale from the 2026-09-05 entry.

| Device | Status | Bootloader |
|--------|--------|-----------|
| `esp32-39_Attic` | 🔴 **Down** — OTA succeeded, device never rejoined network, survived power-cycle attempt. Needs USB recovery. | Old (no rollback) — confirmed by failure |
| `esp32-14_Salon` | ✅ Recovered via USB from M1, 2026-09-06 | **Fixed** — full USB flash from M1 wrote a fresh bootloader; confirmed via clean-boot log, 2026-09-06. No further USB action needed. |
| `esp32-05_Shades_WinterGardenUpp` | ⏸️ Not attempted | Old (no rollback) — per 2026.5.0 cycle note, unconfirmed on 2026.8.2 |
| `esp32-06_Garden_Gateway` | ⏸️ Not attempted | Old (no rollback) — per 2026.5.0 cycle note, unconfirmed on 2026.8.2 |
| `esp32-35_Pump_Garage` | ⏸️ Not attempted (also blocked separately by the override-farm drift, see below) | Old (no rollback) — per 2026.5.0 cycle note, unconfirmed on 2026.8.2 |
| `esp32-36_Garage_Gate` | ✅ Bootloader updated via full USB flash from pMacM5, 2026-09-06 | **Fixed** — `esphome upload` wrote `firmware.factory.bin` at 0x0 (bootloader + partitions + app); hash-verified, clean boot, WiFi + MQTT reconnected |

**Action required before touching the remaining 4 via OTA again:** physical USB session, run `esphome upload --bootloader 2_PROD/<device>.yaml` (or a full `esphome run`, which also refreshes the bootloader) on each of `esp32-39`, `esp32-05`, `esp32-06`, `esp32-35`, starting with recovering Attic. Do this as one batch — same USB cable trip covers all 4. pMacM5 works for this now.

---

## Known Issue — pMacM5 cannot reliably write ESP32-S3 flash over USB (2026-09-06)

> ### ✅ RESOLVED 2026-09-06 (later same day) — it was a disabled driver extension
>
> `systemextensionsctl list` on pMacM5 showed `cn.wch.CH34xVCPDriver` as **`[activated disabled]`** — *not* enabled, despite what the debugging notes below assumed. Enabling it (System Settings → General → Login Items & Extensions → Driver Extensions → toggle CH34xVCPDriver on) flipped it to `[activated enabled]`, and everything below stopped reproducing:
>
> - **Salon** (ESP32-S3, WCH CH9102X UART bridge) now enumerates as **`/dev/cu.wchusbserial58CD1821311`** — the `wchusbserial` node the notes below say "never appeared on M5". The generic `/dev/cu.usbmodem*` fallback was the symptom of the DEXT not claiming the device.
> - `esptool flash-id` on Salon: chip detected (ESP32-S3 QFN56 rev v0.2, 8 MB flash), **stub flasher uploaded and ran**, hard reset via RTS — zero errors. Uploading + running the stub flasher *is* the "bulk data payload to target RAM" operation that previously failed with `0107: Checksum error`. It no longer fails.
> - `esp32-36_Garage_Gate` (ESP32-C3): full `esphome upload` of `firmware.factory.bin` over native USB (`/dev/cu.usbmodem101`) — 837 724 bytes written at 0x0, `Hash of data verified`, device booted and rejoined WiFi + MQTT. Full bootloader + partition + app write, end to end.
>
> **The "bulk USB writes corrupt on pMacM5" / "recent-macOS `IOUSBHostFamily` regression" theory is retired.** Root cause = disabled WCH DEXT; the notes' own leading hypothesis ("pMacM5's WCH cask may need a repair/reinstall to start claiming the device") was directionally correct — it just needed *enabling*, not reinstalling.
>
> **Not fully re-tested:** a literal end-to-end firmware `write-flash` to an ESP32-**S3** from pMacM5 (Salon got the stub-flasher handshake, which uses the identical transfer path, but not a full app write this session). ESP32-C3 full write is confirmed.
>
> **Separate, still open:** direct USB-C↔USB-C from the Mac to the board via a "PD" cable still produced no enumeration at all — most likely a charge-only cable without USB 2.0 D+/D− conductors (CH340/CH9102 is Full-Speed USB 2.0, needs those lines). Not chased further — the working path is a USB **data** cable into a hub. This is a cable property, not a pMacM5 USB-stack fault.

---

**Scope:** this is a finding about the **Mac (pMacM5)**, not about any device config. Confirmed reproducible; not yet reported upstream. *(Superseded — see RESOLVED box above. Kept for the record.)*

### What happened

Attempted USB recovery of `esp32-14_Salon.yaml` (as a precautionary bootloader update, prompted by the Known Issue above) from pMacM5 (MacBook Air M5, very recent macOS — `arm64_tahoe` per Homebrew's platform tag). Board is a genuine Espressif ESP32-S3-DevKitC-1 N8R2 with two USB-C ports (native "USB" + "UART" bridge).

**Symptom, 100% reproducible across every combination tried:**
- Small/control esptool commands always succeed: connect, chip-id read, `SET_ADDRESS`-adjacent handshake, SPI flash erase (a ~1s blocking operation).
- Any command carrying a **bulk data payload** always fails at the first chunk: the stub-flasher upload (`esphome run`/`esphome upload`, both baud rates tried) fails with `Failed to write to target RAM (result was 0107: Checksum error)`; the ROM-loader direct write (`esptool --no-stub write-flash`) fails with `Failed to write to target flash after seq 0 (result was 0105: The format of the received message is invalid)`.
- Failure point never moves, never succeeds, regardless of any of the following (all tried, all identical result):
  - **5 different USB-C cables**
  - **3 different USB hubs** (one independently confirmed fully healthy — enumerated its own hub chip + an unrelated HID USB receiver with zero errors) **and direct connection (no hub)**
  - **Both USB-C ports on the board** (native "USB" — enumerates as `USB JTAG/serial debug unit`/CDC but can't be used for flashing at all, since the auto-reset DTR/RTS circuit isn't wired to it — `No serial data received`; and "UART" bridge — enumerates as `USB Single Serial`/CDC, connects fine, fails on bulk write)
  - **Both USB-C ports on the Mac itself**
  - **Silicon Labs CP210x driver and WCH CH34x driver**, installed/uninstalled/reinstalled in every combination, including neither (Apple's native/generic `AppleUSBCDCCompositeDevice` driver claimed the device either way on pMacM5 — port always showed as generic `/dev/cu.usbmodemXXXX`, never `/dev/cu.wchusbserial*`, even with the WCH cask "activated enabled"). **Confirmed on M1**: same board shows both `/dev/cu.usbmodem58CD1821311` *and* `/dev/cu.wchusbserial58CD1821311` — chip is WCH (CH9102X family), and M1's WCH driver claims it correctly while pMacM5's didn't. This is likely the actual root cause of the bulk-write corruption below, not just a correlating detail — pMacM5's WCH cask install may need a repair/reinstall to start actually claiming the device.
  - macOS's "Allow accessories to connect" security setting (set to always-allow)
  - Board powered via USB only vs. simultaneous 230V + USB
  - Baud rate 9600 (fails to even connect — confirms this is a virtual USB-CDC port, not a real variable-baud UART), 115200, 460800
  - Compressed vs. uncompressed flash write
  - Stub-flasher vs. `--no-stub` (direct ROM-loader) upload path

One early kernel-log capture (direct-connection attempt, before switching to a hub) showed the underlying pattern clearly: `AppleUSBXHCICommandRing::setAddress: completed with result code 4` repeating every ~1.3s until `AppleUSBHostPort::disconnect: persistent enumeration failures` — i.e. the device cycles connect/reconfigure/fail at the USB-protocol level. Later attempts (through a hub) got further — the device stayed enumerated — but any actual bulk data transfer still corrupts consistently.

### Consequence

`esp32-14_Salon.yaml` was down (confirmed via `ping` — router returned "Destination Host Unreachable", same signature as Attic) — each failed `write-flash` attempt genuinely erased the target flash region (0x0–0x15efff, covering bootloader + partition table + app) before the write failed, so after ~5-6 repeated attempts the board's flash in that region was blank. **Recovered 2026-09-06 via a full `esphome run` from Mac Mini M1**, using the `/dev/cu.wchusbserial*` port (not the generic `/dev/cu.usbmodem*` node — M1 has the correct WCH driver claiming the device, unlike pMacM5 at the time).

### Working alternative

The exact same board + firmware + a UART-port cable connection **succeeded on the Mac Mini M1** earlier in this same upgrade cycle (through a USB hub). The bug is specific to pMacM5's USB stack (or its interaction with this device class), not the board, firmware, or cable/hub inventory in general.

### Recommendation

**All superseded by the RESOLVED box at the top of this section — the fix was: enable the `cn.wch.CH34xVCPDriver` system extension (it was `activated disabled`).** Historical notes kept below.

- ~~Recover `esp32-14_Salon` and `esp32-39_Attic` via USB from the **Mac Mini M1**, not pMacM5, until this is resolved.~~ Salon done from M1 2026-09-06; Attic still pending (needs dismount). pMacM5 now works for Attic's recovery.
- ~~Reinstall the `wch-ch34x-usb-serial-driver` cask.~~ Not needed — the cask was installed, its DEXT was just **disabled** in System Settings. Check `systemextensionsctl list` for `[activated enabled]` (not `[activated disabled]`) before any future USB session.
- The macOS-regression / esptool-bug theories were never needed.
- Nothing to file upstream — not an esptool or Espressif issue.

### Ruled out: GPIO20/native-USB conflict is not the cause

The compile log (both M1 and, verified separately, pMacM5) shows: `WARNING GPIO20 is used by the USB-Serial-JTAG interface. Using this pin as GPIO will conflict with USB-Serial-JTAG.` `esp32-14_Salon.yaml` assigns `GPIO20` as I2C `bus_a` SCL (`interfaces/i2c.yaml`). This is a real, pre-existing config note — GPIO20 is electrically the native USB-Serial-JTAG D+ line on ESP32-S3 — but it is **not** related to the pMacM5 bulk-write bug:
- It's a static compile-time config warning, identical on both Macs (confirmed by recompiling on pMacM5) — it doesn't depend on which machine or USB port is used.
- It concerns the chip's **native** USB-Serial-JTAG peripheral (GPIO19/20). Flashing was done through the **external WCH UART bridge** (separate physical UART TX/RX pins, e.g. GPIO43/44) — electrically independent of GPIO20.
- I2C on `bus_a` only initializes once application firmware boots; during the actual flash write (ROM bootloader / stub flasher) the app isn't running yet, so GPIO20's I2C role can't interfere with that transfer.

**Fixed anyway, 2026-09-06**, while the case was open for the pMacM5 recovery: moved `bus_a` SCL from `GPIO20` to `GPIO47` (free pin, adjacent to `GPIO48` which the RGB LED already uses safely — confirmed Quad-mode PSRAM on this N8R2 module, so 47/48 aren't PSRAM-reserved). Required a physical wire move on the board (not just a config change) — done, reflashed via OTA, BME680 + BH1750 both confirmed reading again. Salon's native "USB" port is now free to use in the future without any I2C conflict.

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
| `esp32-14_Salon` | ✅ Recovered 2026-09-06, bootloader fixed too | OTA'd fine 2026-09-05 (bootloader-too-old warning noted). USB precautionary bootloader update attempted 2026-09-06 from pMacM5 hit the pMacM5 USB bulk-write bug (see Known Issue above), flash region erased across ~5-6 attempts. **Recovered via full `esphome run` from Mac Mini M1** using `/dev/cu.wchusbserial*` — that full flash also refreshed the bootloader; confirmed via clean-boot log, warning gone, no further USB action needed for this device |
| `esp32-39_Attic` | 🔴 **Down** | OTA reported success but device never rejoined network; survived a physical power-cycle attempt with no change. Needs USB recovery — deferred, no USB port near the physical install location (attic), needs dismount first. pMacM5 works for this now (WCH DEXT fixed 2026-09-06). |
| `esp32-06_Garden_Gateway` | ⏸️ Paused | Held back pending USB bootloader update round (shares Attic's old-bootloader risk) |
| `esp32-05_Shades_WinterGardenUpp` | ⏸️ Paused | Held back pending USB bootloader update round |
| `esp32-36_Garage_Gate` | ✅ Done 2026-09-06 | Bootloader updated via full USB `esphome upload` from pMacM5 (`firmware.factory.bin` at 0x0); hash-verified, clean boot, WiFi + MQTT reconnected |
| `esp32-35_Pump_Garage` | ⏸️ Paused | Held back for USB bootloader round **and** the separate override-farm drift fix (see Known Issue above) — both must be resolved first |
| `0_DEV/esp32_dev_display.yaml` | ✅ Done 2026-09-05 | `select.state` → `.current_option()` fixed — no longer blocks compiling on ≥2026.7.0 |

**Next step**: `esp32-14_Salon` (recovered + bootloader-fixed from M1) and `esp32-36_Garage_Gate` (bootloader-fixed from pMacM5) — done. Remaining: one USB session (pMacM5 or M1 — both work now) covering `esp32-39` (full recovery, needs dismount from attic first — deferred to a separate visit), `esp32-05`, `esp32-06`, `esp32-35` (bootloader update; esp32-35 also needs the override-farm drift fix) — then resume OTA rollout for the remaining 3 (esp32-05/06/35).

---

## Open Questions for Pawelo

- ~~**Garage_Gate hardware**: Hörmann or DIY?~~ **Answered 2026-09-05**: it's a **Wiśniewski** gate operator (2009), no remote/bus protocol — `hoermann_hcp` is not applicable, relay+endstop via `esp32-36_Garage_Gate.yaml` remains the correct approach.
- **LD6002b (60GHz radar)**: worth evaluating as a hardware upgrade anywhere the existing 24GHz LD2410/LD2420 give unreliable presence readings? This is a new purchase, not a firmware-only change.
- ~~**`Key '...' was dropped while processing a '<<' merge` warning (logger/time/mqtt) on every compile that uses override-by-order — silence via `esphome: { merge_warnings: false }` in board_*.yaml?**~~ **Answered 2026-09-06**: leave as-is. Confirmed intentional/expected behavior (10 of 11 PROD devices use override-by-order), cosmetic only, not worth touching 4-6 shared board files for log noise.

---

## References

- [ESPHome 2026.6.0 changelog](https://esphome.io/changelog/2026.6.0/)
- [ESPHome 2026.7.0 changelog](https://esphome.io/changelog/2026.7.0/)
- [ESPHome 2026.8.0 changelog](https://esphome.io/changelog/2026.8.0/)
- [GitHub releases (2026.8.1, 2026.8.2 patch notes)](https://github.com/esphome/esphome/releases)
